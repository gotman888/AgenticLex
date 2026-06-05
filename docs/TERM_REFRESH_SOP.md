# 詞庫更新 SOP — 跟著 Claude Code 一起更新用詞

> Claude Code **每週多版**、用詞常改名/新增（如 Task→Agent tool、`/vim` 移除）。
> 詞庫當 **living doc**：每 **2–4 週** refresh 一次，每個 CC minor bump 硬 re-audit。
> 來源錨點：**code.claude.com/docs**（CC docs 已搬到此域）+ `/release-notes` + changelog。

---

## 每次 refresh（4 步）

### 1. 跑落差研究（自動）
```
Workflow: claudecode-term-gap-research        （.claude/workflows/，可直接按名跑）
```
- 8 面向 fan-out 查 live docs → 對抗式驗證 → 彙整 gap report。
- agent 會**自己讀 `terms.en.json`** 當「已覆蓋」基準，只回 GAPS → 不需手動更新清單。
- 產出貼回 **`docs/TERM_BACKLOG.md`**（覆蓋舊報告，留版本日期）。

### 2. 挑批次
- 從 backlog 依 **P0 > P1 > P2** + **isNew** 挑一批（建議**一類一批**：commands / settings / tools …）。
- 先處理 **outdatedOrRename**（修 shipped 內容的準確性，最高優先）。

### 3. 加詞（內容流程，照紅線）
每個新詞要動 **7 個檔**：
- **`terms.en.json`**（master）：加 `terms[]` 條目 `{ id, english, category, pronunciation(IPA), difficulty(1-3), isEnglishOnly, tags[], relatedTerms[], addedDate }`；新類加 `categories[]` `{ id, icon(SF Symbol), order, names{7} }`。
- **`terms.{zh-TW,zh-CN,ja,ko,es,pt}.json`**：各加 `translations[id]` `{ term, definition, example, memoryHook, realUse, commonConfusion?, status, translator, updated }`。
- **status 規則**：新加的全標 `"ai"`（含 zh-TW 草稿）→ app 的 **AI badge** 會顯「未審校」；母語者（zh-TW = 王宏盟本人）審過再翻 `"verified"`。其餘 5 語系維持 `ai`（與既有一致）。
- **風格**：定義口語、example 真實情境、memoryHook 助記、**不焦慮**；英文錨點保留（isEnglishOnly 的詞 term 留英文+短 gloss）。
- en-native 無翻譯（master-only，placeholder）——別為 en 寫 translations。

### 4. 驗證 + 收尾
```bash
cd ClaudeCodeLex/Resources
# JSON 有效 + 詞庫一致（每 locale 對 en master 0 missing / 0 extra）
python3 -c "import json,glob; m=json.load(open('terms.en.json')); ids={t['id'] for t in m['terms']}; [print(f.split('/')[-1], 'missing',len(ids-set(json.load(open(f)).get('translations',{}))),'extra',len(set(json.load(open(f)).get('translations',{}))-ids)) for f in sorted(glob.glob('terms.*.json')) if not f.endswith('terms.en.json') and not f.endswith('/terms.json')]"
# i18n（若加了新類的 UI 字串才需；category names 在 terms.en.json 不在 Localizable.strings）
```
- 更新各 locale 檔的 `coverage`（totalTerms/translated/verified/ai）。
- 更新 `terms.en.json` metadata `version`（bump）+ `updated`（今天）。
- `xcodegen generate`（若沒加檔可略）+ `xcodebuild ... build` 驗綠。
- 一批一 commit（等 user 說 commit）。改了 app → 重 sync 公開 repo（skill `repo-publish` / `tools/build_public_snapshot.py`）。

---

## 已知陷阱
- `/vim` 已移除 → **別加**。`TodoWrite`（v2.1.142+ 停用）標註已停用。
- **Task Tool → Agent Tool**（v2.1.63）、**Agent SDK → Claude Agent SDK**：rename 不刪，主名改、舊名當 alias/註記。
- IPA 對 `/compact`、`settings.json` 這種符號/代碼詞意義不大 → 用口語唸法或留空（schema 允許簡化）。
- 低/中信心項（subagent_type 等）ship 前再對 live docs 核一次。

## 相關
- 落差清單：`docs/TERM_BACKLOG.md`
- 加詞標準步驟：`CLAUDE.md`「常見任務 → 加新詞」
- 研究 workflow：`.claude/workflows/claudecode-term-gap-research.js`
