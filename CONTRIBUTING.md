# Contributing to AgenticLex

Thanks for helping! The most valuable contribution is **improving translations**
— turning machine-translated (`ai`) entries into native-reviewed (`verified`)
ones, or fixing wording that doesn't sound natural.

## The dictionary

All vocabulary lives in `ClaudeCodeLex/Resources/`:

```
terms.en.json      ← English master (canonical: ids, category, IPA, difficulty…)
terms.zh-TW.json   ← 繁體中文 translations
terms.zh-CN.json   ← 简体中文
terms.ja.json      ← 日本語
terms.ko.json      ← 한국어
terms.es.json      ← Español
terms.pt.json      ← Português
```

Each locale file is keyed by the **term id** from `terms.en.json`:

```jsonc
"translations": {
  "mcp": {
    "term": "MCP（模型上下文協定）",
    "definition": "…",
    "example": "…",
    "memoryHook": "…",          // optional mnemonic
    "realUse": "…",             // optional real-world usage snippet
    "commonConfusion": "…",     // optional "don't confuse with…"
    "status": "verified",       // "verified" | "ai"
    "translator": "your-name"
  }
}
```

### Improving a translation

1. Find the term id in `terms.en.json`.
2. Edit the matching entry in your locale file (`terms.<locale>.json`).
3. If you're a native speaker who reviewed it, set `"status": "verified"` and
   put your name/handle in `"translator"`.
4. Keep the English term as the anchor — translations are scaffolding, they
   don't replace the English the learner is here to master. Terms that read
   better untranslated (MCP, API, hook, token…) can keep the English with a
   short gloss.

### Adding a new term

1. Add it to `terms.en.json` (give it an `id`, `category`, `pronunciation`,
   `difficulty`, `tags`, `relatedTerms`).
2. Add the matching translation key to **every** locale file.

## Verify before you PR

Run these from the repo root (Python 3):

```bash
# 1. Dictionary: every locale covers every English term, no extras
python3 -c "
import json
m = json.load(open('ClaudeCodeLex/Resources/terms.en.json'))
ids = {t['id'] for t in m['terms']}
import glob
for f in sorted(glob.glob('ClaudeCodeLex/Resources/terms.*.json')):
    if f.endswith('terms.en.json') or f.endswith('terms.json'): continue
    z = json.load(open(f)); zi = set(z.get('translations', {}))
    print(f.split('/')[-1], 'missing:', len(ids-zi), 'extra:', len(zi-ids))
"

# 2. UI strings: all 7 locales share the same keys
python3 -c "
import re, glob
keys = {}
for f in glob.glob('ClaudeCodeLex/Resources/*.lproj/Localizable.strings'):
    loc = f.split('/')[-2].replace('.lproj','')
    keys[loc] = set(re.findall(r'^\"([^\"]+)\"\s*=', open(f).read(), re.M))
base = keys['en']
for loc, ks in keys.items():
    if loc == 'en': continue
    diff = (base-ks)|(ks-base)
    print(loc, 'OK' if not diff else f'DIFF {len(diff)}')
"
```

## UI string changes

UI strings are in `Resources/*.lproj/Localizable.strings`. There are **7
locales and they must stay key-for-key in sync** — if you add a key, add it to
all 7 files. The script above checks this.

## Ground rules

- **Device-only forever.** No backend, no analytics, no tracking SDKs — please
  don't add any. It's a core promise (the App Store privacy label is all-green).
- API keys belong in the Keychain, never `UserDefaults`.
- Be kind in the copy — the app's whole tone is calm and encouraging.

## License of contributions

By contributing you agree that code is licensed under MIT and dictionary content
under CC BY 4.0, matching the rest of the project (see `LICENSE`).
