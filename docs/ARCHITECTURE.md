# AgenticLex — Architecture Review

> v0.4 / 2026-05-20
> 完整的 codebase 拆解、設計決策回顧、技術債清單、Xcode 整合 checklist
> 給 Claude Code 接手前的 senior architect's overview

---

## 1. 一句話描述

**AgenticLex** 是一個 iOS 16+ SwiftUI 單 binary app，給「會用 AI 的非英文母語人」學習 Claude Code 等 agentic coding 工具的英文術語。**100% 離線可用，BYOK 可選升級體驗。0 後端、0 帳號、0 追蹤。**

---

## 2. 系統分層

```
┌──────────────────────────────────────────────┐
│                    Views (UI)                 │
│  ContentView → Tab (Today/Browse/Quiz/Settings)
│  + Onboarding (gated)                         │
│  + Modal: TermDetail / ListenMode /           │
│           AskLexi / TipJar / Achievements /   │
│           AIBoost                              │
└─────────────────┬────────────────────────────┘
                  │ @EnvironmentObject / @StateObject
                  ▼
┌──────────────────────────────────────────────┐
│                  Services                     │
│  TermStore    — 詞庫 (terms.en.json + locale) │
│  ProgressStore — 學習進度 + SRS + 連勝         │
│  AppSettings  — UserDefaults 偏好             │
│  SpeechService — TTS 統一介面 (native+cloud)  │
│  AIVoiceService — Cloud TTS HTTP 客戶端       │
│  AIVoicePlayer — mp3 播放                     │
│  AIChatService — Ask Lexi 對話 API            │
│  TipJarService — StoreKit 2 IAP               │
│  KeychainHelper — API key 安全存取            │
└─────────────────┬────────────────────────────┘
                  ▼
┌──────────────────────────────────────────────┐
│                   Models                      │
│  Term / Translation / Category (詞庫)         │
│  UserProgress (學習狀態)                       │
│  Achievement (徽章)                            │
│  AIVoiceProvider / AIChatProvider (BYOK)      │
│  ChatMessage / SpokenItem                     │
└──────────────────────────────────────────────┘
```

依賴方向：**Views → Services → Models**（單向、無循環）。

---

## 3. 檔案地圖 (33 Swift + 16 Resources)

### 3.1 App 入口 (1 檔)

| 檔案 | 行數 | 職責 |
|---|---|---|
| `App/ClaudeCodeLexApp.swift` | 24 | `@main`、@StateObject 注入 termStore / progressStore / settings |

### 3.2 Models (4 檔, 364 行)

| 檔案 | 行數 | 主要型別 |
|---|---|---|
| `Models/Term.swift` | 88 | `TermsMainBundle`, `Term`, `CategoryMeta`, `LocaleBundle`, `LocalizedTranslation`, `TranslationStatus`, `Coverage` |
| `Models/UserProgress.swift` | 31 | `UserProgress`, `LearnStatus` |
| `Models/Achievement.swift` | 112 | `Achievement`, `AchievementSnapshot`, `Achievements.all` (10 個) |
| `Models/AIProvider.swift` | 133 | `AIVoiceProvider`, `AIChatProvider`, `VoiceOption` |

### 3.3 Services (9 檔, 1199 行)

| 檔案 | 行數 | 職責 |
|---|---|---|
| `Services/AppSettings.swift` | 72 | 全部 @AppStorage、`voiceProvider`/`chatProvider` 屬性轉換 |
| `Services/TermStore.swift` | 124 | 載入 terms.en.json + terms.{locale}.json、search、translation lookup |
| `Services/ProgressStore.swift` | 154 | 進度 JSON 持久化、SRS 排程、streak 計算 |
| `Services/SpeechService.swift` | 295 | AVSpeechSynthesizer wrapper + 3 檔速 + Listen Mode + cloud TTS dispatch |
| `Services/AIVoiceService.swift` | 91 | OpenAI TTS + ElevenLabs HTTP 客戶端 |
| `Services/AIVoicePlayer.swift` | 57 | mp3 解碼播放 + lock screen |
| `Services/AIChatService.swift` | 190 | Claude / OpenAI / Gemini 統一 chat completion |
| `Services/TipJarService.swift` | 93 | StoreKit 2 IAP |
| `Services/KeychainHelper.swift` | 63 | `kSecClassGenericPassword` wrapper |

### 3.4 Views (12 個畫面, 1880 行)

| 檔案 | 行數 | 進入點 |
|---|---|---|
| `Views/ContentView.swift` | 37 | Root，gated on onboarding |
| `Views/OnboardingView.swift` | 234 | 第一次開 app 走 3 屏 |
| `Views/TodayView.swift` | 265 | Home Tab：Lexi greet + WOTD + picks + Listen/Random |
| `Views/BrowseView.swift` | 65 | Browse Tab：search + category chips + list |
| `Views/QuizView.swift` | 297 | Quiz Tab：`QuizSetupView` + `QuizCardView` + `QuizResultView` + `ReviewSessionView` |
| `Views/SettingsView.swift` | 124 | Settings Tab |
| `Views/TermDetailView.swift` | 220 | 大字 hero + translation + example + Lexi 對話入口 |
| `Views/ListenModeView.swift` | 178 | 純聽連播畫面 |
| `Views/AchievementsView.swift` | 78 | 徽章網格 |
| `Views/TipJarView.swift` | 121 | 3 級贊助 |
| `Views/AIBoostView.swift` | 357 | BYOK Settings 子頁 |
| `Views/AskLexiView.swift` | 250 | 對話 sheet |

### 3.5 Components (7 個, 729 行)

| 檔案 | 行數 | 用途 |
|---|---|---|
| `Views/Components/LexiView.swift` | 294 | 紫色 owl-bot 吉祥物，6 poses |
| `Views/Components/CelebrationView.swift` | 159 | 撒花 + Lexi 慶祝 overlay |
| `Views/Components/TermCard.swift` | 87 | `TermCardMini` (h-scroll) + `TermRow` (list) |
| `Views/Components/SpeakerButton.swift` | 78 | 圓形播放鈕、pulse 動畫、長按速度選 |
| `Views/Components/AppColor.swift` | 52 | 設計 tokens + SF Pro Rounded helper |
| `Views/Components/Block.swift` | 37 | Section block with label |
| `Views/Components/CategoryChip.swift` | 22 | Pill-shape category badge |

### 3.6 Resources (16 檔)

```
Resources/
├── terms.en.json          ← 主檔（categories + term metadata）
├── terms.zh-TW.json       ← zh-TW 翻譯
├── terms.json             ← v1 deprecated stub (不要 include 進 bundle)
├── Tips.storekit          ← IAP 設定（給 simulator 測試）
├── en.lproj/Localizable.strings
├── zh-Hant.lproj/Localizable.strings
├── ja.lproj/Localizable.strings
├── ko.lproj/Localizable.strings
├── es.lproj/Localizable.strings
└── pt.lproj/Localizable.strings
```

---

## 4. 關鍵設計決策回顧

### 4.1 為什麼 SwiftUI 而非 UIKit

- iOS 16+ 已涵蓋 95%+ 裝置，SwiftUI 在這版本起足夠成熟
- 雙主題 / Dynamic Type / VoiceOver 開箱即用
- 適合 indie dev 維護

### 4.2 為什麼 terms.json schema 拆檔（v2）

- 一個 JSON 大檔 = 任何一個 PR 都會衝突
- 主檔 + 各 locale 獨立 = 社群 PR 友善
- 啟動只 load 必要 locale，省記憶體

### 4.3 為什麼 SRS 用簡化版 SM-2

- 完整 SM-2 對 30-100 個詞 over-engineering
- 1d / 3d / 7d / 30d / 90d 五階段足夠
- 之後加詞庫到 500+ 再升級

### 4.4 為什麼 BYOK 用 Keychain 而非 UserDefaults

- UserDefaults 是明文 plist，越獄機 / 備份外洩風險
- Keychain 加密 + 系統管理 + 不進 iCloud backup（除非顯式設）
- 用 `kSecAttrAccessibleAfterFirstUnlock` 平衡安全與可用

### 4.5 為什麼 cloud TTS fallback 到 native

- 網路斷、API 額度爆、key 失效時 user 仍能聽
- 體驗連續性 > 「品質一致性」
- Toast 提醒 user 但不打斷學習

### 4.6 為什麼 Ask Lexi 用 system prompt 而非 fine-tune

- 30 個詞太小，fine-tune 不划算
- system prompt 動態組合 = 每個詞都有 context
- 換 provider 不用重訓

### 4.7 為什麼吉祥物用 SwiftUI shape 而非 PNG

- 完美 vector，任何 size 都銳利
- Dark mode 自動適配（PNG 要兩套）
- 6 poses 共用 ~290 行，可動畫、可上色
- bundle 大小 0 增加

---

## 5. 已知技術債（收尾要修）

| 優先 | 項目 | 影響 | 修法 |
|---|---|---|---|
| P0 | 20 個 unused i18n keys (category.cli/hooks/... + today.greeting + settings.disclaimer) | bundle size + 翻譯維護成本 | 清掉，剩下 ~158 keys |
| P0 | `terms.json` v1 stub 還在 | 容易誤加 Xcode bundle | 寫進 Xcode setup checklist 明確排除 |
| P1 | `ReviewSessionView` 在 QuizView.swift 裡（命名不直觀） | 找檔難 | 拆出 `Views/ReviewSessionView.swift` 或在 doc 標註 |
| P1 | `AIChatService` 沒 streaming（一次拿完整 reply） | UX 慢 1-3 秒 | v0.5 加 SSE streaming |
| P1 | `Celebration` 結構的 `Equatable` 實作回 false | 邊角 case | v0.5 改成穩定的 identity 比對 |
| P2 | TodayView pickedTerms 邏輯 naive（不分 due / new） | 學習效果次優 | v0.5 用 SRS 真實 due 排程 |
| P2 | 沒有 unit test | 重構風險 | v0.5 加 XCTest 至少覆蓋 ProgressStore / TermStore |
| P3 | LexiView 動畫一定跑 (animated default true) | 省電？ | 看 reduce motion accessibility |

---

## 6. Xcode 整合 Checklist

### 6.1 建 Xcode project

1. Xcode → File → New → Project → iOS App
   - Product Name: `ClaudeCodeLex` (內部 code name)
   - Display Name 之後在 Info.plist 改成 `AgenticLex`
   - Interface: SwiftUI / Language: Swift / Storage: None
   - Min iOS: **16.0**

### 6.2 拖入檔案（Copy items + Create groups + add to target）

```
App/ClaudeCodeLexApp.swift               (刪 Xcode 預設的)
Models/*.swift                            (4 個)
Services/*.swift                          (9 個)
Views/*.swift                             (12 個)
Views/Components/*.swift                  (7 個)
Resources/terms.en.json                   ← 必加
Resources/terms.zh-TW.json                ← 必加
Resources/Tips.storekit                   ← 必加
Resources/*.lproj/Localizable.strings     (6 個語系)

⚠️ NOT to add (重要)
Resources/terms.json                      (deprecated stub)
```

### 6.3 Info.plist 必要設定

| Key | Value | 用途 |
|---|---|---|
| `CFBundleDisplayName` | `AgenticLex` | App 圖示下顯示名 |
| `UIBackgroundModes` | `audio` | Listen Mode 背景播放 |
| `UISupportedInterfaceOrientations` | `Portrait` only | 單手體驗 |
| `UIRequiresFullScreen` | `NO` | iPad split-view 友善 |

### 6.4 Project Settings

- **Localizations**：加 zh-Hant / ja / ko / es / pt
- **Capabilities**：In-App Purchase（給 Tip Jar）
- **Signing**：免費 dev account 可跑 simulator，上架要 paid $99/yr

### 6.5 Scheme

- Run → Options → StoreKit Configuration → `Tips.storekit`（simulator 測 IAP）

### 6.6 編譯 sanity check

```bash
# 在 Xcode terminal 跑：
xcodebuild -scheme ClaudeCodeLex \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build
```

---

## 7. 部署到 App Store Checklist

### 7.1 必備素材
- [ ] App Icon 1024×1024 PNG
- [ ] 6 張 iPhone 6.7" 截圖
- [ ] 6 張 iPhone 6.5" 截圖
- [ ] App Preview 影片（可選但建議）
- [ ] Privacy Policy URL（GitHub Pages）
- [ ] Support URL（mailto: 或 GitHub）

### 7.2 App Store Connect 設定
- [ ] App Name: AgenticLex
- [ ] Subtitle 6 語系（見 `docs/APPSTORE_METADATA.md`）
- [ ] Description 6 語系
- [ ] Keywords 6 語系
- [ ] In-App Purchase × 3（tip.small/medium/large）
- [ ] Privacy nutrition: No data collected
- [ ] Age rating: 依 Apple 問卷誠實作答（含 Ask Lexi BYOK AI 對話，新制下不一定維持 4+）

### 7.3 BYOK 審核補充說明（給 reviewer 看）

填在 Submit 時 "Notes to Reviewer"：

> AgenticLex includes optional BYOK (Bring Your Own Key) features:
> - Users may paste their own API keys for OpenAI / ElevenLabs / Anthropic / Google
> - Keys are stored locally in iOS Keychain only
> - Requests go directly from device to the provider
> - We do NOT offer subscriptions to those providers in-app
> - We do NOT have any backend servers
> - This matches the model used by ChatGPT, Voicedream Reader, Pal Chat, etc.

---

## 8. 模組化擴張指引（給 Claude Code）

### 加新詞

修改 `Resources/terms.en.json` + `terms.zh-TW.json`，**id 用 slug**（小寫連字號）。例：

```json
{
  "id": "new-term-here",
  "english": "New Term",
  "category": "tools",
  "pronunciation": "/njuː tɜːrm/",
  "difficulty": 2,
  "isEnglishOnly": false,
  "tags": ["new"],
  "relatedTerms": [],
  "addedDate": "2026-06-01"
}
```

### 加新語系

1. 新增 `Resources/<locale>.lproj/Localizable.strings`（複製 en，翻譯）
2. 新增 `Resources/terms.<locale>.json`（複製 zh-TW 結構，翻譯）
3. 更新 `terms.en.json` metadata.fullyTranslatedLocales 加入該 locale
4. `AppSettings.supportedLanguages` 加 entry
5. Xcode → Project → Localizations → 加該語言

### 加新 AI provider

1. `Models/AIProvider.swift` 加 enum case + voices/keychainAccount
2. `Services/AIVoiceService.swift`（TTS）或 `AIChatService.swift`（chat）加新 method
3. `Services/SpeechService.swift` 的 `speakCloud` switch 加 case
4. `Views/AIBoostView.swift` 自動跑（ForEach AIVoiceProvider.allCases）

### 加新徽章

`Models/Achievement.swift` 的 `Achievements.all` array 加一個 `Achievement`，補對應 i18n key。

### 加新畫面

1. 在 `Views/` 新增 .swift
2. 從某個現有 view link 進去（如 SettingsView 加 NavigationLink）
3. 不需動 ContentView（TabView 4 個 tab 已固定）

---

## 9. 文件交叉引用圖

```
README.md  ← 簡介，指向 HANDOFF.md
   │
   ▼
HANDOFF.md  ← 人類入口 (master)
   ├─→ CLAUDE.md      (Claude Code 啟動讀)
   ├─→ ROADMAP.md     (剩下要做)
   ├─→ CHANGELOG.md   (做過的)
   └─→ docs/INDEX.md  (詳細章節導覽)
            │
            ├─→ 01_PRD.md
            ├─→ 02_DESIGN.md
            ├─→ 03_ARCHITECTURE.md (本份)
            ├─→ 04_SCHEMA_V2.md
            ├─→ 05_FRIENDLY_LEARNING.md
            ├─→ 06_AI_BYOK_DESIGN.md
            ├─→ 07_OPTIMIZATION.md
            └─→ 08_APPSTORE_METADATA.md
```

---

End of ARCHITECTURE.md
