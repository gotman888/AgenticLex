# ClaudeCodeLex — Product Requirements Document (PRD)

> Code name: **ClaudeCodeLex**（Lex = lexicon 詞典）
> App Store 對外名稱建議：**Claude Code Lex** / 副標 *Learn the language of agentic coding*
> Author: 王宏盟 (gotman888@gmail.com)
> Date: 2026-05-20
> Status: v0.1 (MVP scope locked)

---

## 1. 願景 (Vision)

讓「非英文母語、非程式背景、但要用 Claude Code 工作」的人，能在通勤、零碎時間，用**聲音 + 視覺 + 例句**快速吸收 Claude Code 生態的英文術語，把「看不懂的 jargon」變成「我知道在說什麼」。

一句話：**Duolingo 的學習節奏 × Claude Code 的專業詞彙。**

---

## 2. 目標受眾 (Target Audience)

主受眾 (Primary)
- 非英文母語的 Claude Code / Cursor / Cline 使用者
- 自學 vibe coders、PM、設計師、文案、行政、業務、研究者
- 母語：繁中、簡中、日、韓、西、葡（首版優先 zh-TW / ja / ko / es / pt）
- 聽力學習偏好者 (auditory learner)

次受眾 (Secondary)
- 想跨入 agentic coding 但卡英文的學生
- ESL teachers 想教 AI 時代技術英文

非受眾 (Not for)
- 已經 fluent 的英文母語工程師
- 想學 general programming English 的人（本 app 聚焦 CC ecosystem）

---

## 3. MVP 範圍 (v1.0 App Store Launch)

### Must-have（必出）
1. **Term Browse**：按分類 (CLI / Hooks / MCP / Sub-agents / Plugins / Skills / Artifacts / Tool Use / Prompting / Misc) 瀏覽 30 個核心詞彙
2. **Term Detail**：英文詞 + 母語翻譯 + 定義 + 真實使用例句 + 記憶 hook
3. **Audio Pronunciation**：點擊播放，用 `AVSpeechSynthesizer` (en-US voice)、支援語速調整
4. **Quiz Mode**：閃卡 (flashcard) en→母語 / 母語→en 雙向
5. **Progress Tracking**：每個詞標記 new / learning / mastered，本地存 JSON
6. **Spaced Repetition (SRS Lite)**：mastered 30 天後重排回 review
7. **UI 多語系**：en, zh-TW, ja, ko, es, pt 六語系
8. **離線可用**：所有功能不需網路（TTS 用 iOS 內建 voice）

### Should-have (v1.1 1 個月內)
- Daily streak 連續學習天數
- Term 收藏 (favorite ⭐)
- 分享單詞卡片到 Twitter/IG (圖片產生)

### Could-have (v1.5+)
- Apple Watch widget「今日 1 詞」
- Siri Shortcuts: "Hey Siri, 今天的 CC 單字"
- Community 翻譯貢獻 (Crowdin)
- 使用者新增自定義詞

### Won't-have（MVP 不做）
- 帳號系統 / 雲端同步（先全本地，省 GDPR 與成本）
- 內購 / 付費功能（**永久免費**，這是 user 承諾）
- 影片教學
- 社群留言

---

## 4. 核心使用者旅程 (User Journey)

```
第一次開 app
└─ 選母語 (auto detect from iOS locale, 可改)
   └─ 選每日學習目標 (3 / 5 / 10 詞)
      └─ 落到 Home (Today 畫面)
         ├─ 看到「今日推薦 5 詞」
         ├─ 點第一張卡 → Term Detail
         │  ├─ 大字英文 "Slash Commands"
         │  ├─ 點 🔊 → AVSpeechSynthesizer 讀
         │  ├─ 看母語翻譯「斜線指令」+ 定義 + 例句
         │  ├─ 看到記憶 hook 提示
         │  └─ 滑掉 / 標記 mastered
         ├─ 學完 5 詞 → 進入 Quiz
         │  └─ 5 題閃卡測驗 → 答對標 mastered
         └─ 看到「streak +1🔥」
```

---

## 5. 功能規格細節 (Feature Specs)

### 5.1 Term 資料模型

| 欄位 | 型別 | 範例 | 說明 |
|---|---|---|---|
| `id` | String | `"slash-commands"` | slug，跨語系穩定 |
| `english` | String | `"Slash Commands"` | 首字大寫 |
| `category` | enum | `cli` | 11 大類之一 |
| `pronunciation` | String? | `"/slæʃ kəˈmændz/"` | IPA，optional |
| `difficulty` | Int (1-3) | 2 | 排序與漸進用 |
| `translations` | Dict<locale, T> | … | 見下 |
| `relatedTerms` | [String] | `["hooks", "skills"]` | id ref |
| `tags` | [String] | `["cli", "shortcut"]` | 搜尋用 |

`translations[locale]` 結構：
- `term`: 翻譯後的詞（如「斜線指令」）
- `definition`: 完整定義（母語）
- `example`: 真實 CC 使用例句（混 EN + 母語講解）
- `memoryHook`: 記憶法 / 助記（如「slash = / 鍵，輸入 /help 就會看到」）

### 5.2 Audio (TTS)

- 技術：`AVSpeechSynthesizer` + `AVSpeechUtterance`
- 語言：`AVSpeechSynthesisVoice(language: "en-US")`
- 語速：UI 提供 0.4 / 0.5 (default) / 0.6 三檔
- 設定保存：UserDefaults `audio.rate`
- 重音字（如 "agentic"）特別加慢速 0.45

### 5.3 Quiz 模式

- 兩種題型：
  - **EN → L1**：看英文選母語翻譯（4 選 1）
  - **L1 → EN**：看母語選英文詞（4 選 1）
- 干擾選項從同 category 抽
- 答對 → 進度 +1（new→learning→reviewing→mastered）
- 答錯 → 不退階，但 24h 內再排
- 結束顯示 5/5 動畫 + streak

### 5.4 SRS 演算法（簡化版 SM-2）

```
status: new → learning → reviewing → mastered
答對:
  new → learning, next = +1 day
  learning → reviewing, next = +3 days
  reviewing → mastered, next = +30 days
  mastered → mastered, next = +90 days
答錯:
  → new, next = +1 day
```

決定不用完整 SM-2，因 MVP 不需要那麼精準，使用者體感更重要。

### 5.5 多語系策略

| 層級 | 工具 | 維護方 |
|---|---|---|
| App UI 字串 | `Localizable.xcstrings` (String Catalog, iOS 15+) | 王宏盟 + 社群 PR |
| 詞庫翻譯 | `terms.json` 內嵌 translations dict | 王宏盟 + Crowdin (v1.5+) |
| TTS 語言 | iOS 內建，無需翻譯 | — |

v1.0 內容覆蓋度：
- zh-TW：100% (王宏盟手寫)
- en：100% (base)
- ja / ko / es / pt：UI 100%，詞庫定義可先用 Claude 翻譯 + 母語審校 (v1.0 出 zh-TW + en 即可，其他語系定義先 fallback en)

---

## 6. 非功能性需求 (NFR)

| 項目 | 目標 |
|---|---|
| 平台 | iOS 16.0+ (覆蓋 ~95% device) |
| 設計 | SwiftUI (no UIKit unless 必要) |
| 套件 | Apple 原生 only (no 3rd-party SDK)，方便上架審核 |
| 隱私 | 0 蒐集，0 cookies，0 帳號，0 追蹤。Privacy nutrition label 全綠 |
| 大小 | < 15 MB (no 預錄音檔) |
| 啟動時間 | cold start < 1.5s on iPhone 12 |
| 離線 | 100% 功能離線可用 |
| 無障礙 | VoiceOver 完整支援、Dynamic Type、reduce motion |
| 主題 | Auto / Light / Dark |

---

## 7. 上架計畫 (App Store Launch)

### Phase 0: 開發 (今日 ~ T+14 天)
- 此 session 產出 MVP code skeleton
- 王宏盟用 Claude Code 在 Xcode 內擴展、修 bug、加翻譯

### Phase 1: TestFlight Beta (T+14 ~ T+21)
- 申請 Apple Developer Program ($99/yr)
- 上 TestFlight，找 10-20 個 Claude Code 社群朋友試
- 收 feedback 修

### Phase 2: App Store Submission (T+21 ~ T+28)
- 準備：
  - App icon (1024×1024)
  - 截圖 6 張（中英對照、quiz、detail、settings、home、browse）
  - App preview 影片 (optional)
  - Privacy Policy URL (產一份簡單版掛 GitHub Pages)
  - Support URL (email or GitHub Issues)
- 審核重點：
  - 教育類 (Education)
  - 0 IAP, 0 廣告, 0 帳號
  - 描述清楚說「unofficial, Claude Code is trademark of Anthropic」避免商標糾紛
- 預計審核 1-3 天

### Phase 3: 上架後 (T+28+)
- 開 GitHub repo open-source (可選)
- 寫一篇中英 blog post 宣傳
- 投稿 Hacker News / Reddit r/ClaudeAI
- v1.1 開發

### 商標與法律注意
- **不可用 "Claude Code" 為 app 名**（Anthropic 商標）
- 建議名：
  - **Lex for Claude** ✅
  - **CodeWords: Claude Edition** ✅
  - **AgenticLex** ✅
  - 描述中明確聲明 "This app is not affiliated with or endorsed by Anthropic. Claude Code is a trademark of Anthropic PBC."

---

## 8. 風險與假設 (Risks & Assumptions)

| 風險 | 影響 | 緩解 |
|---|---|---|
| Anthropic 抗議商標 | App 下架 | 改名 + 加免責，事前 email Anthropic legal 報備 |
| 詞庫變動快 (CC 一直更新) | 內容過時 | v1.5 加 OTA content update (從 GitHub 拉 JSON) |
| TTS 發音怪 (e.g. "MCP") | 學習效果差 | 用 `AVSpeechUtterance.preUtteranceDelay` + IPA 文字補強 |
| 上架被拒 (Apple review) | Delay | 第一輪用最保守 metadata，被拒再迭代 |
| zh-CN 市場？ | 跳過後悔 | v1.1 加 zh-CN (從 zh-TW OpenCC 轉碼即可) |

---

## 9. 成功指標 (Success Metrics, post-launch)

> 全本地，無 analytics，只能靠 App Store Connect 看：

| 指標 | 目標 (3 個月) |
|---|---|
| Downloads | 1,000+ |
| Crash-free rate | > 99.5% |
| Avg rating | > 4.3 |
| Reviews | > 30 條，含 2+ 種語系 |

---

## 10. 開放議題 (Open Questions, for 王宏盟)

- [ ] App 名最終決定？（建議 **Lex for Claude**）
- [ ] App icon 風格？（建議：紫色漸層 + 書本 + /  符號）
- [ ] 是否同時 open-source on GitHub？（建議 yes，吸引社群翻譯）
- [ ] 後續詞庫由誰維護？（建議 GitHub PR + 王宏盟 review）

---

## Appendix A: 詞彙分類 (Category Taxonomy)

| Category Key | 顯示名 (zh-TW) | 顯示名 (en) | 範例詞 |
|---|---|---|---|
| `cli` | 指令列基礎 | CLI Basics | Slash Commands, Status Line, Session |
| `hooks` | Hook 鉤子 | Hooks | PreToolUse, PostToolUse, SubagentStop |
| `mcp` | MCP 協定 | MCP | MCP Server, Tool, Resource, Prompt |
| `sub-agent` | 子代理人 | Sub-agents | Sub-agent, Delegation, Task tool |
| `plugins` | 插件 | Plugins | Marketplace, .plugin, Plugin manifest |
| `skills` | 技能 | Skills | SKILL.md, Trigger, Skill bundle |
| `artifacts` | 產出物 | Artifacts | HTML artifact, React artifact, Live artifact |
| `tools` | 工具 | Tools | Read, Edit, Write, Bash, Glob, Grep |
| `context` | 上下文 | Context | Context window, Token, Compaction, CLAUDE.md |
| `prompting` | 提示工程 | Prompting | System prompt, Tool result, Few-shot |
| `misc` | 其他 | Misc | Worktree, Permission, Background task |

---

End of PRD v0.1
