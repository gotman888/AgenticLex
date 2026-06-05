# ClaudeCodeLex — 深度優化檢討 (v0.2 thinking)

> 2026-05-20 / 對 v0.1 MVP 的二輪 review
> 主題：(A) App Store 上架競爭力 (B) 英文錨點 × 多語系輻射的 i18n 思維

---

## 0. TL;DR — 5 個非改不可的點

| # | 問題 | 影響 | 改動成本 |
|---|---|---|---|
| 1 | App 名綁 "Claude Code" 商標 | 上架審核被拒風險 + 未來擴張卡死 | 低（改名 + 改 metadata） |
| 2 | i18n 是「翻譯」非「轉創」 | 各語系市場下載與留存差 | 中（重寫 6 語系 tagline / ASO） |
| 3 | 4 語系內容空殼但 UI 假裝支援 | 上架後負評 + Apple 4.2 拒審 | 中（v1.0 縮回 2 語系 + 標 Coming Soon） |
| 4 | 英文錨點設計沒推到極致 | 學習效果打折 | 低（quiz default + UI 微調） |
| 5 | ASO / 軟啟動 / 商業模式空白 | 上架後沒人下載 | 中（寫 metadata + 1 國軟啟動） |

---

## A. App Store 上架 — 深度檢討

### A1. App 命名重新思考 ⚠️ P0

**現況問題**
- "ClaudeCodeLex" 直接組合 Anthropic 兩個商標 ("Claude" + "Claude Code")
- 商標 nominative fair use 在「描述」OK，當「product name」風險高
- 與 Anthropic 官方未來可能推出的學習工具撞名

**三個命名方向**

| 命名 | 立場 | Pros | Cons |
|---|---|---|---|
| `Lex for Claude` | 親近但仍依附 | 易懂 | 仍含商標，未來變窄 |
| **`AgenticLex`** ✅ | 概念派 (推薦) | 涵蓋 Claude/Cursor/Cline 整個生態，無商標、可擴張 | 第一次聽不知是什麼 |
| `CodeLingo: AI Edition` | 教育派 | 像學習 app，避商標 | 名稱已有同名競品 |

**最終建議**：**`AgenticLex`** + 副標 *Learn the language of AI coding*
- 內部 code name 維持 `ClaudeCodeLex` 不改 (省工)
- 首版詞庫聚焦 Claude Code，但 ASO / 描述涵蓋整個 agentic coding 生態
- 商標聲明從 settings 底部 → 移到 onboarding 首頁

### A2. 商業模式：不只是「免費」⚠️ P1

**現況**：純免費、無付費

**優化建議**：**Free + Tip Jar (non-functional IAP)**
- 主 app 100% 免費、所有功能可用
- Settings 加「☕ Buy me a coffee」 → 3 個 consumable IAP：$0.99 / $4.99 / $19.99
- 不解鎖任何功能 → 純贊助
- 為何要加：
  1. Apple 審核員偏好「有商業模式」的 app（不是必要但加分）
  2. 給死忠 user 表達感謝的管道
  3. 服務器 / 詞庫維護費可持續
- 上架後第 1 個月就可加，不影響首版

### A3. ASO (App Store Optimization) 重新設計 ⚠️ P0

**現況**：我給的 keywords 只有英文，沒考慮各語系搜尋習慣。

**正確做法**（每語系都要這 4 件事）：

| 欄位 | 限制 | 範例 (zh-TW) | 範例 (ja) |
|---|---|---|---|
| App Name | 30 字元 | AgenticLex - AI編程詞典 | AgenticLex - AI英単語 |
| Subtitle | 30 字元 | Claude Code 等英文術語學習 | Claude Code を理解する英語 |
| Keywords | 100 字元 (逗號分隔，無空格) | claude,code,mcp,prompt,英文,術語,程式,學習,單字 | クロード,英語,プログラミング,単語,AI,MCP |
| Promotional Text | 170 字元 (可隨時改) | 新增 30 個 Hook / Skill 詞彙！ | フックとスキルの単語30個追加！ |

**ASO 心法**
- Keywords 不要重複 app name 已含字
- 各語系搜尋習慣不同：日本市場常搜「英単語」+ tech name；韓國搜「영단어」；西語搜「vocabulario」
- Promotional Text 是每版上架後改詞，不需重審

### A4. 截圖策略：6 語系 × 6 張 = 36 套 ⚠️ P1

**現況**：我寫了 6 張英文截圖

**優化**：每語系獨立截圖（Apple 顯示時依使用者 locale 自動切）
- 不只是「翻譯文字」，要「轉創 tagline」
- 範例 tagline 對照：

| 語系 | 截圖 1 tagline |
|---|---|
| en | Learn the language of agentic coding |
| zh-TW | 用 5 分鐘，讀懂 AI 編程的英文 |
| ja | 1日5分、AI コーディングの言葉を学ぶ |
| ko | 하루 5분, AI 코딩의 언어를 배우다 |
| es | 5 minutos al día para hablar AI coding |
| pt | 5 minutos por dia para falar AI coding |

**生產建議**：用 Figma / Sketch / Canva 做 6×6 = 36 圖。Claude Code 可以幫你產 SwiftUI screenshot 程式，跑 simulator 截圖再覆蓋 tagline。

### A5. Privacy Policy / Support URL ⚠️ P0 (Apple 必要)

**現況**：placeholder

**最便宜做法**：GitHub Pages 免費掛
1. 開 repo `agenticlex-docs` (public)
2. 加 `privacy.md` + `support.md`
3. 啟用 GitHub Pages
4. URL：`https://gotman888.github.io/agenticlex-docs/privacy`

**Privacy Policy 內容極簡版**（因為 app 真的沒收資料）：
> AgenticLex does not collect, store, or transmit any personal information. All learning data stays on your device. No analytics, no tracking, no third-party SDKs.
> Contact: gotman888@gmail.com

### A6. TestFlight 軟啟動策略 ⚠️ P1

**現況**：直接上架

**優化**：4 階段釋出

```
Phase 0 (T+0):  TestFlight Internal — 自己 + 3 個密友
Phase 1 (T+7):  TestFlight Public Link — 開放 GitHub / X 邀 100 人
                ↳ 重點收：6 語系翻譯品質、TTS 發音怪在哪
Phase 2 (T+14): App Store 軟啟動 (Taiwan only)
                ↳ 觀察 7 天，看 retention / 評論
Phase 3 (T+21): 全球釋出 (165 國)
```

**為何要分**：Apple 一旦審過，要改地區是免費的。但出問題回收的成本（負評洗版）很高。

### A7. Crash 監測：不裝 SDK 也能有 ⚠️ P2

**現況**：0 監測（符合 0 收集承諾）

**優化**：Xcode Organizer 內建 crash report
- 不用裝任何 SDK，不用 Firebase / Sentry
- 使用者要「同意分享診斷資料」（iOS 系統層級）才會回傳
- 在 Xcode → Organizer → Crashes 看
- 完全符合「0 第三方追蹤」原則

### A8. 上架審核常見地雷 ⚠️ P0

| 拒審條款 | 風險 | 緩解 |
|---|---|---|
| 4.2 Minimum Functionality | 詞典型 app 常被當「不夠 substantial」 | 強調學習功能 (quiz / SRS / progress)、不要描述成「dictionary」描述成 "learning tool" |
| 4.3 Spam | 「跟 X app 太像」 | 強調聚焦 agentic coding niche，不是 general English |
| 5.2 Trademark | 用他人商標 | 1. 不在 app name 用 "Claude" 2. 截圖中所有 Claude 字樣加 ™ 3. 明顯位置加 disclaimer |
| 2.3.10 Inaccurate Metadata | 截圖跟實際 app 不一樣 | 截圖一定要從 simulator 真實抓 |
| 4.7 HTML5 Games | 用 WebView 太多 | N/A，我們純 SwiftUI |

### A9. 開源策略 ⚠️ P2

**建議**：上架後 1 週開源
- repo: `github.com/gotman888/AgenticLex` (MIT for code, CC BY 4.0 for content)
- 為何要 open：吸引社群翻譯詞庫 → 解 A3 內容空殼問題
- 為何 1 週後：先看上架反應，避免被搶名 / 被 fork 上架

### A10. 版本節奏 ⚠️ P1

**現況 PRD**: 1.0 → 1.1 → 1.5 → 2.0 太鬆

**優化節奏**（學 Duolingo / Anki 經驗）：
- v1.0.0 (T+30): MVP 上架 (en + zh-TW)
- **v1.0.1 (T+35): 修上架收的小 bug、加 1 語系**
- v1.1 (T+50): 收藏 export、share 卡片
- v1.2 (T+80): 加 zh-CN + 補完 ja
- v1.5 (T+150): OTA 詞庫更新 + Apple Watch
- 心法：每 2-3 週小版上架一次，演算法會喜歡「active app」

---

## B. i18n 思維重塑 — 英文錨點輻射模型

### B1. 思維模型升級

**v0.1 模型**（錯）：
```
[en, zh-TW, ja, ko, es, pt] 平等的 6 語系翻譯陣列
```

**v0.2 模型**（對）：
```
        ENGLISH ANCHOR
       (canonical, never changes)
       /     |     |     \
     zh-TW   ja    ko     es / pt
     (helper, 助記用，可有可無)
```

**含義**
- 英文是學習目標，**永遠不可隱藏、不可替代**
- 母語只是「助記翻譯」(scaffolding)，幫你記住英文
- UI 的所有「主視覺位置」屬於英文
- 母語在「次位置」、字級較小、顏色較淡

### B2. UI 層具體修正 ⚠️ P0

對應到 v0.1 程式碼有些做對了、有些沒：

| 元件 | v0.1 現況 | v0.2 修正 | 檔案 |
|---|---|---|---|
| TermCardMini | ✅ 英文大、母語小 | OK | TermCard.swift |
| TermRow | ✅ 英文 16pt、母語 caption | OK | TermCard.swift |
| TermDetailView hero | ⚠️ 英文 40pt 偏小 | 改 56pt + 加重音標示 | TermDetailView.swift |
| Quiz Setup default | ❌ default `enToL1` | **改 default `l1ToEn`** （想英文才是學） | QuizView.swift |
| BrowseView 搜尋 | ✅ 雙向搜尋 | OK | BrowseView.swift |
| TodayView greeting | ⚠️ 純母語問候 | 英文 word of the day 放最上 | TodayView.swift |
| Settings 順序 | ⚠️ UI 語系在前 | UI 語系與母語語系**分開明說** | SettingsView.swift |

### B3. 「Untranslatable」概念 ⚠️ P1

**問題**：很多 CC 詞「翻成中文反而難懂」（MCP, JSON, REST, API, sub-agent）
- "MCP" 翻成「模型上下文協定」其實沒幫助，user 就是要記得 MCP
- "sub-agent" 翻成「子代理人」勉強，但業界都直接說 sub-agent

**解法**：terms.json 加 `isEnglishOnly: Bool`
- true 時，UI 顯示：
  - 英文大字
  - 「**保留英文不譯**」標籤
  - 定義改寫成「為什麼這個詞英文比中文好用」
- 候選 isEnglishOnly: MCP, API, REST, JSON, hook, prompt, token, agent, SDK

### B4. Quiz 方向重新設計 ⚠️ P0

**v0.1 quiz 預設**：英文 → 母語（看 "MCP" 選「模型上下文協定」）
- 這是「測試你懂不懂這個英文詞」
- 對母語者學英文無用

**v0.2 quiz 預設**：母語 → 英文（看「模型上下文協定」選 "MCP"）
- 這是「測試你能不能回想出英文詞」
- 才是真正的學習

**進階模式**：「拼字測驗」(spelling)
- 給定母語、給定英文首字母 "M__"，使用者輸入完整 "MCP"
- 對 PreToolUse / SubagentStop 這種複合詞特別有用

### B5. 內容覆蓋誠實宣告 ⚠️ P0

**現況**：UI 顯示支援 6 語系，但 terms.json 只有 zh-TW 翻譯
- 使用者切到日文：詞庫全 fallback 到英文（看起來像 bug）
- 上 App Store 用 ja 描述吸日本 user 來，發現只有英文 → 1 星評價

**v1.0 上架建議**：縮回 **en + zh-TW** 兩語系
- ja/ko/es/pt 在 settings 顯示但標 *Coming soon — help us translate!*
- 點下去顯示「我們需要你的協助」+ GitHub link
- 誠實 + 社群動員 = 雙贏

**v1.0 之後**：每補完一語系才開放該語系

### B6. 翻譯品質的三級制 ⚠️ P1

每個 translation 應該有狀態：
```swift
enum TranslationStatus: String {
    case verified   // 母語者審過 ✓
    case ai         // Claude 翻的，未審 (灰底)
    case missing    // 無翻譯，fallback to en
}
```

UI 上：
- `ai` 顯示時加「🤖 AI 翻譯，未審校」小標
- 加 [回報問題] 按鈕

### B7. App UI 字串 vs 詞庫翻譯：分開治理 ⚠️ P1

**現況**：兩者都叫 "i18n"，但本質完全不同

| 類型 | 變動頻率 | 維護方 | 工具 |
|---|---|---|---|
| App UI strings (66 keys) | 很低 (功能加才改) | 王宏盟 | Localizable.strings |
| 詞庫翻譯 (terms × locales) | 高 (每加詞要加全部語系) | 王宏盟 + 社群 | terms.json |

**v2 建議**：詞庫拆分檔
```
Resources/
├── terms.en.json        (英文 + 元資料)
├── terms.zh-TW.json     (只有翻譯)
├── terms.ja.json        (只有翻譯)
└── terms.ko.json
```
- 好處：社群 PR 只改自己語系檔，不衝突
- 加新詞時：先 update terms.en.json，其他語系自動標 missing

### B8. 發音不只是英文 ⚠️ P2

**現況**：只播英文發音

**v2 延伸**：母語也可發音（給聽力學習強的 user）
- TermDetail 中，translation block 旁邊也加 🔊
- 點下去用 AVSpeechSynthesizer 對應 locale 唸母語翻譯
- 對日韓 user 特別有用（他們可能漢字認得但不確定唸法）

### B9. 排序：locale-aware ⚠️ P2

Browse list 預設按 JSON 順序，應該是 locale-aware：

| Locale | 排序 |
|---|---|
| en | A-Z (English alphabet) |
| zh-TW | 筆畫 or 注音 (取拼音首字) |
| ja | 五十音 |
| ko | 가나다 |
| es / pt | A-Z |

實作：用 `String.localizedCompare(_:)` + 該 locale 的母語 term。

### B10. 數字與單位 locale ⚠️ P2

`🔥 7` 在純數字外，應該配 locale 量詞：
- en: `🔥 7 days`
- zh-TW: `🔥 7 天`
- ja: `🔥 7日`
- ko: `🔥 7일`
- es: `🔥 7 días`
- pt: `🔥 7 dias`

用 `NumberFormatter` + 字串模板，不要 hardcode。

### B11. RTL 預留 ⚠️ P3

不在 v1.0 範圍，但程式碼避免：
- 不用 `.leading` / `.trailing` 寫死方向
- ✅ 已用 `.leading` / `.trailing` （非 `.left` / `.right`）
- 之後加阿拉伯文 (ar) / 希伯來文 (he) 直接支援

### B12. 一次性 onboarding ⚠️ P1

**現況**：auto detect locale，跳過 onboarding

**v2 優化**：第一次開 app 走 3 屏：

```
Screen 1: 「Welcome」
   - app logo + tagline (顯示 locale 自動)

Screen 2: 「Which language do you read tech docs in?」
   - English / 中文 / 日本語 / 한국어 / Español / Português
   - 預設選 system locale，可改
   - 這決定 UI 語言

Screen 3: 「Which language helps you learn faster?」
   - 同上選項
   - 決定 native (translation) 語言
   - 為何分開：很多人 UI 想要英文（顯酷），但 native 想要中文（好記）

Screen 4: 「Daily goal?」
   - 3 / 5 (推薦) / 10 / 20 words

Screen 5: 「You're all set ✨」
   - 進入 Today tab
```

### B13. App Store 描述：分語系不同訴求 ⚠️ P1

**錯誤做法**：把英文描述翻譯成各語系

**正確做法**：每語系有自己的「為什麼這個 app 對你」訴求點

| 語系 | 訴求點 |
|---|---|
| en | "Master AI coding vocabulary" (assume already a user, 你已是 CC user，想加速) |
| zh-TW | "Claude Code 看不懂英文？5 分鐘就上手" (你被英文卡住，這 app 救你) |
| ja | "英語が苦手でも Claude Code が使える" (對日本 user，痛點是英文門檻) |
| ko | "영어 부담 없이 Claude Code 정복" (同日本) |
| es | "Claude Code en tu idioma" (西語社群英文流暢度有差，強調本地化) |
| pt | "Claude Code no seu idioma" (同上) |

---

## C. terms.json schema v2 升級提案

對應 B3 / B6 / B7：

```json
{
  "$schema": "1.0.0",
  "metadata": {
    "version": "2.0.0",
    "updated": "2026-05-20",
    "source": "Claude Code documentation",
    "supportedLocales": ["en", "zh-TW", "ja", "ko", "es", "pt"]
  },
  "categories": [...],
  "terms": [
    {
      "id": "mcp",
      "english": "MCP",
      "category": "mcp",
      "pronunciation": "/ɛm siː piː/",
      "difficulty": 2,
      "isEnglishOnly": true,
      "tags": ["mcp", "protocol"],
      "relatedTerms": ["mcp-server", "tool"],
      "translations": {
        "zh-TW": {
          "term": "MCP (模型上下文協定)",
          "definition": "...",
          "example": "...",
          "memoryHook": "...",
          "status": "verified",
          "translator": "王宏盟",
          "updated": "2026-05-20"
        },
        "ja": {
          "term": "MCP",
          "definition": "...",
          "example": "...",
          "memoryHook": null,
          "status": "ai",
          "translator": "claude-sonnet-4-6",
          "updated": "2026-05-19"
        }
      }
    }
  ]
}
```

---

## D. 上架前 checklist (整理)

**Must-have before submission**
- [ ] App rename 完成 (建議 AgenticLex)
- [ ] App icon 1024×1024 ready
- [ ] Privacy Policy URL live (GitHub Pages)
- [ ] Support URL live
- [ ] 6 截圖 × 2 語系 (en + zh-TW only for v1.0)
- [ ] App Store description × 2 語系
- [ ] Keywords × 2 語系 (ASO 過)
- [ ] Trademark disclaimer 在 onboarding 顯示
- [ ] Apple Developer Program 通過
- [ ] TestFlight 內部測過 3+ 人 / 7+ 天

**Nice-to-have v1.0.1+**
- [ ] App Preview 影片
- [ ] Tip Jar IAP
- [ ] zh-CN locale
- [ ] 開源 repo
- [ ] Blog post (中英)
- [ ] HN / Reddit 宣傳

---

## E. 我的建議優先序

| Priority | 改動 | 理由 |
|---|---|---|
| **P0** (一定做) | A1 改名, A3 ASO, A5 Privacy URL, A8 商標 disclaimer, B2 UI 微調, B4 quiz 預設方向, B5 內容覆蓋誠實 | 影響能不能上架 + 上架後第一印象 |
| **P1** (強烈建議) | A2 Tip Jar, A4 截圖, A6 軟啟動, A10 版本節奏, B3 isEnglishOnly, B6 翻譯狀態, B12 onboarding, B13 分語系訴求 | 影響長期下載與留存 |
| **P2** (有空再做) | A7 crash 監測, A9 開源, B8 母語發音, B9 排序, B10 量詞 | 沒做也能上 |
| **P3** (未來) | B11 RTL | v2.0 才碰 |

---

End of OPTIMIZATION.md
