#!/usr/bin/env python3
"""fetch_reviews.py — pull AgenticLex App Store customer reviews (read-only).

OWNER-SIDE DEV INFRASTRUCTURE. Runs on your Mac, NOT in the shipped app — so the
app's device-only / no-tracking promise is untouched. It only reads public
review data from App Store Connect using your ASC API key.

What it does
------------
1. Mints a short-lived ES256 JWT from your ASC API key (.p8).
2. GETs /v1/apps/{APP_ID}/customerReviews (newest first, paginated).
3. Prints new reviews since the last run, appends them to a dated log, and
   emits a triage prompt you (or Claude Code) can act on:
     - translation bug   -> fix terms.*.json + (later) OTA push
     - UX bug / request   -> add a docs/ROADMAP.md item
     - praise             -> note in CHANGELOG / keep morale up

Setup (once)
------------
  pip install pyjwt cryptography          # JWT signing (ES256)
  # In App Store Connect → Users and Access → Integrations → App Store Connect API,
  # create a key (role: at least "App Manager" can read reviews). Download the .p8.
  export ASC_KEY_ID=XXXXXXXXXX
  export ASC_ISSUER_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  export ASC_KEY_PATH="$HOME/.appstoreconnect/AuthKey_XXXXXXXXXX.p8"
  # APP_ID defaults to AgenticLex (6771639472); override with ASC_APP_ID if needed.

Run
---
  python3 tools/fetch_reviews.py            # new reviews since last run
  python3 tools/fetch_reviews.py --all      # ignore the state file, fetch a page

State + log live next to this script under tools/.feedback/ (git-ignored).
"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
from datetime import datetime, timezone
from pathlib import Path

APP_ID = os.environ.get("ASC_APP_ID", "6771639472")  # AgenticLex
API = "https://api.appstoreconnect.apple.com/v1"
STATE_DIR = Path(__file__).resolve().parent / ".feedback"
STATE_FILE = STATE_DIR / "last_run.json"
LOG_FILE = STATE_DIR / "intake.log"


def die(msg: str) -> "NoReturn":
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def make_token() -> str:
    try:
        import jwt  # PyJWT
    except ImportError:
        die("PyJWT not installed. Run: pip install pyjwt cryptography")
    key_id = os.environ.get("ASC_KEY_ID")
    issuer = os.environ.get("ASC_ISSUER_ID")
    key_path = os.environ.get("ASC_KEY_PATH")
    if not (key_id and issuer and key_path):
        die("set ASC_KEY_ID, ASC_ISSUER_ID, ASC_KEY_PATH (see header).")
    if not Path(key_path).exists():
        die(f"ASC_KEY_PATH not found: {key_path}")
    private_key = Path(key_path).read_text()
    now = int(time.time())
    payload = {"iss": issuer, "iat": now, "exp": now + 1200, "aud": "appstoreconnect-v1"}
    return jwt.encode(payload, private_key, algorithm="ES256",
                      headers={"kid": key_id, "typ": "JWT"})


def get(url: str, token: str) -> dict:
    req = urllib.request.Request(url, headers={"Authorization": f"Bearer {token}"})
    try:
        with urllib.request.urlopen(req, timeout=30) as r:
            return json.loads(r.read().decode())
    except urllib.error.HTTPError as e:
        die(f"HTTP {e.code} from ASC: {e.read().decode()[:300]}")
    except urllib.error.URLError as e:
        die(f"network error: {e}")


def fetch_reviews(token: str, limit: int = 50) -> list:
    url = (f"{API}/apps/{APP_ID}/customerReviews"
           f"?sort=-createdDate&limit={min(limit, 200)}")
    data = get(url, token)
    out = []
    for item in data.get("data", []):
        a = item.get("attributes", {})
        out.append({
            "id": item.get("id"),
            "rating": a.get("rating"),
            "title": a.get("title", ""),
            "body": a.get("body", ""),
            "reviewer": a.get("reviewerNickname", ""),
            "territory": a.get("territory", ""),
            "date": a.get("createdDate", ""),
        })
    return out


def load_state() -> dict:
    if STATE_FILE.exists():
        return json.loads(STATE_FILE.read_text())
    return {"last_review_date": ""}


def save_state(state: dict) -> None:
    STATE_DIR.mkdir(exist_ok=True)
    STATE_FILE.write_text(json.dumps(state, indent=2))


def main() -> None:
    fetch_all = "--all" in sys.argv
    token = make_token()
    reviews = fetch_reviews(token)
    state = load_state()
    since = "" if fetch_all else state.get("last_review_date", "")
    new = [r for r in reviews if r["date"] > since] if since else reviews

    STATE_DIR.mkdir(exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    if not new:
        print(f"[{stamp}] no new reviews ({len(reviews)} total on first page).")
        return

    print(f"[{stamp}] {len(new)} new review(s):\n")
    with LOG_FILE.open("a") as log:
        log.write(f"\n=== intake {stamp} — {len(new)} new ===\n")
        for r in new:
            stars = "★" * (r["rating"] or 0) + "☆" * (5 - (r["rating"] or 0))
            line = (f"{stars} [{r['territory']}] {r['date'][:10]} — {r['title']}\n"
                    f"    {r['body']}\n    — {r['reviewer']}\n")
            print(line)
            log.write(line)

    # advance the watermark to the newest review we saw
    state["last_review_date"] = max(r["date"] for r in reviews)
    save_state(state)

    print("""
Triage each one:
  • translation bug   -> fix ClaudeCodeLex/Resources/terms.*.json (+ OTA push once dict is published)
  • UX bug / request   -> add a docs/ROADMAP.md §7 item
  • praise             -> note in CHANGELOG; reply in App Store Connect if it asks a question
Then re-run after acting; the watermark above means you only see new ones next time.
""")


if __name__ == "__main__":
    main()
