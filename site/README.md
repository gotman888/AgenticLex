# AgenticLex — public pages

Source for the legal/support pages App Store review requires (ROADMAP §4.3).
Plain Markdown, rendered by GitHub Pages (Jekyll).

| File | Becomes |
|---|---|
| `index.md` | site landing page |
| `privacy.md` | Privacy Policy — App Store Connect "Privacy Policy URL" |
| `support.md` | Support page — App Store Connect "Support URL" |

## Deploy to GitHub Pages

`site/` lives inside the AgenticLex git repo, so create the docs repo
separately — do **not** `git init` inside this folder (it would nest a repo).

```bash
# 1. create the empty public repo
gh repo create gotman888/agenticlex-docs --public

# 2. clone it OUTSIDE the AgenticLex repo, copy these pages in
cd ~/Code
gh repo clone gotman888/agenticlex-docs
cp ~/Code/ClaudeCodeLex/site/*.md agenticlex-docs/
cd agenticlex-docs
git add -A && git commit -m "Add privacy, support, index pages"
git push

# 3. enable GitHub Pages (main branch, repo root)
gh api -X POST repos/gotman888/agenticlex-docs/pages \
  -f 'source[branch]=main' -f 'source[path]=/'
```

Result (live after ~1 min):

- Privacy Policy URL → `https://gotman888.github.io/agenticlex-docs/privacy`
- Support URL → `https://gotman888.github.io/agenticlex-docs/support`

Put those two URLs into App Store Connect when filling app metadata.
