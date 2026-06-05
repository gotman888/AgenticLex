# Feedback Ops — turning signal into backlog

> How user feedback becomes improvements. AgenticLex is device-only (no backend,
> no analytics), so signal arrives through three doors. This doc is the loop that
> converts those into `terms.*.json` fixes, ROADMAP items, and CHANGELOG notes.

---

## The three doors

| Door | Where | Tooling |
|---|---|---|
| **App Store reviews** | public, per-territory | `tools/fetch_reviews.py` (read-only ASC API) |
| **Feedback / report email** | `gotman888@gmail.com` | in-app mail composer (prefilled with build/locale/term context) |
| **TestFlight feedback** | App Store Connect → TestFlight | (manual for now; ASC betaFeedback API can be added to the script later) |

### In-app capture (what the app already sends you)
- **Settings → Send feedback** opens a mail draft prefilled with a diagnostic
  footer (app+build version, iOS, device, UI/native locale, dictionary version).
- **Term detail → Report a problem or suggest a fix** opens the same composer
  auto-filled with the term id / English / current translation + status, so a
  bad translation arrives already identified.
- AI-translated terms (ja/ko/es/pt/zh-CN, `status:"ai"`) show an **"AI translation
  — not yet reviewed"** badge, so users know which ones most need their eyes.
- A polite **App Store rating prompt** fires after a quiz, once per app version,
  only for engaged users (streak ≥3 AND ≥10 mastered) — this is what grows the
  review volume the fetcher reads.

---

## Weekly loop (≈10 min)

1. **Pull reviews**
   ```bash
   python3 tools/fetch_reviews.py        # new App Store reviews since last run
   ```
   Skim the feedback inbox (Gmail label `agenticlex` recommended) and the
   TestFlight feedback tab.

2. **Triage** each item into one bucket:
   | Bucket | Action |
   |---|---|
   | Translation bug / better wording | Edit `ClaudeCodeLex/Resources/terms.<locale>.json`; if a native speaker confirmed it, flip `status` to `verified`. Ship via the next build **and** push to the OTA `dict/` folder so existing users get it without an update. |
   | UX bug / missing feature | Add a `docs/ROADMAP.md` §7 item with the source (review/email) noted. |
   | Praise / question | Note in `CHANGELOG.md`; reply in App Store Connect if it asks something. |
   | Crash | Check Xcode → Organizer → Crashes (no SDK needed; users opt in via iOS diagnostics). |

3. **Close the loop visibly.** When you ship a dictionary fix via OTA, the in-app
   updater can surface "Dictionary updated" — frame future copy as *"thanks to
   learner feedback"* so the people who reported get the satisfaction of seeing it
   land. (Requires publishing the OTA `dict/` folder; see `TermUpdateService`.)

4. **Log.** `fetch_reviews.py` appends each intake to `tools/.feedback/intake.log`
   and advances a watermark so you only ever see new reviews.

This finally puts a mechanism behind the two long-standing acceptance items:
`docs/ROADMAP.md` §4.4 "收 5 條以上 feedback" and §6.3 "Reviews ≥1 條 4 星以上".

---

## Automate the pull (optional, launchd)

Run the fetch every Monday 09:00 and let it print to a log you skim. Save as
`~/Library/LaunchAgents/com.agenticlex.reviews.plist`, then
`launchctl load` it.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>            <string>com.agenticlex.reviews</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>/Users/YOU/Code/ClaudeCodeLex/tools/fetch_reviews.py</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>ASC_KEY_ID</key>     <string>XXXXXXXXXX</string>
    <key>ASC_ISSUER_ID</key>  <string>xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx</string>
    <key>ASC_KEY_PATH</key>   <string>/Users/YOU/.appstoreconnect/AuthKey_XXXXXXXXXX.p8</string>
  </dict>
  <key>StandardOutPath</key>  <string>/Users/YOU/Code/ClaudeCodeLex/tools/.feedback/cron.log</string>
  <key>StandardErrorPath</key><string>/Users/YOU/Code/ClaudeCodeLex/tools/.feedback/cron.err</string>
  <key>StartCalendarInterval</key>
  <dict><key>Weekday</key><integer>1</integer><key>Hour</key><integer>9</integer><key>Minute</key><integer>0</integer></dict>
</dict>
</plist>
```

> Keep ASC credentials out of git — they live in your shell env / this plist, and
> `tools/.feedback/` is git-ignored. Nothing here ships in the app.
