# AgenticLex — Roadmap

> 從 v0.4 → v1.0 上架的剩餘任務清單。
> 每個 task 含：**acceptance criteria** (做完算 OK 的標準) + **預估工時** + **Claude Code prompt 範本**

---

## 0. 任務優先序總覽

```
v0.5  Polish & Cleanup    (1 週)  ✦ 上 Xcode 前必做
v0.6  Content Expansion   (1 週)  ✦ 詞庫到 60 個
v0.7  Visual Assets       (1 週)  ✦ App icon / 截圖
v0.8  TestFlight Beta     (2 週)  ✦ 內測 + 公測
v0.9  Localization Push   (2 週)  ✦ ja/ko AI 翻譯 + 審
v1.0  App Store Launch    (1 週)  ✦ 軟啟動 → 全球
```

---

## 1. v0.5 — Polish & Cleanup（必做）

### 1.1 清理 unused i18n keys
**狀態**：✅ DONE (2026-05-20)
**為何**：v0.2 / v0.3 改架構後留下未用 keys（11 個 category.cli/hooks/... + today.greeting + quiz.result.done + settings.disclaimer）
**修正**：原估「20 個」有誤。20 個「字面未用」裡有 6 個是動態組鍵、**不可刪**：
`askLexi.poweredBy.{claude,gemini,openai}`（`"askLexi.poweredBy.\(provider.rawValue)"`）
+ `audio.speed.{slow,normal,fast}`（`"audio.speed.\(tier.rawValue)"`）。實際可刪 = **14 個**。
**Acceptance**：
- [x] 移除 14 個未用 keys（6 語系同步）
- [x] 驗證腳本回報 164 keys × 6 全一致（178 − 14）
- [ ] App build 過 / VoiceOver 不報缺字串 → 延後到路徑 A 進 Xcode 後驗

**工時**：30 分（實際 ~15 分）

**Claude Code prompt**：
> 跑 docs/ARCHITECTURE.md §5 提到的 unused i18n audit，列出 20 個未在 Swift 用的 keys，從 6 個 Localizable.strings 同步刪除。改完跑驗證腳本確認 keys 數一致。

---

### 1.2 拆 ReviewSessionView 成獨立檔
**狀態**：✅ DONE (2026-05-20)
**為何**：目前藏在 QuizView.swift，找檔不直觀
**Acceptance**：
- [x] 新增 `Views/ReviewSessionView.swift`
- [x] QuizView.swift 留純 quiz 邏輯
- [x] TodayView 引用點不變

**工時**：15 分

---

### 1.3 補 reduce motion 支援
**狀態**：✅ DONE (2026-05-20)
**為何**：LexiView 一直浮動、confetti 一直撒，省電與 a11y 需要
**Acceptance**：
- [x] LexiView 讀 `@Environment(\.accessibilityReduceMotion)`
- [x] reduce motion 開啟時：不浮動、不眨眼、confetti 改 fade-in
- [ ] 設定 → Accessibility → Motion → Reduce Motion 測試過（待 sim 跑通後驗）

**工時**：20 分

---

### 1.4 Quiz 答對加 Celebration overlay
**狀態**：✅ DONE (2026-05-20)
**為何**：v0.3 寫了 CelebrationOverlay 但只在 result 用，single answer 答對也應該慶祝
**實作**：`CelebrationView.swift` 新增 `QuickConfetti`（非 modal、自動淡出）；`QuizCardView` 答對 `confettiTrigger += 1` 觸發、答錯 `showHug` 浮現 Lexi。
**Acceptance**：
- [x] QuizCardView 答對時 0.5s 短 confetti（非 modal）
- [x] haptic .success
- [x] 答錯時 Lexi hug 浮現 1s

**工時**：30 分

---

### 1.5 ProgressStore 加 unit test
**狀態**：✅ DONE (2026-05-20)
**為何**：SRS 邏輯關鍵，重構安全網
**Acceptance**：
- [x] 至少 5 個 test：`Tests/ProgressStoreTests.swift` 共 9 個（new→learning / learning→reviewing / wrong→new / streak 等）
- [x] 跑 ⌘U 全綠 — 9 個 test 全過（2026-05-22 `xcodebuild test` 驗過）

**工時**：1.5 小時

---

## 2. v0.6 — Content Expansion

### 2.1 詞庫加到 60 個
**狀態**：✅ DONE (2026-05-20)
**為何**：30 個太少，App Store 描述寫「30+ growing」要兌現
**實作**：新增 30 個詞（與既有 30 個無重複），分布 cli 7 / hooks 7 / mcp 5 / sub-agent 4 / plugins 4 / skills 5 / artifacts 4 / tools 8 / context 6 / prompting 6 / misc 4 = 60。
**Acceptance**：
- [x] terms.en.json 新增 30 個詞（schema v2，含 IPA / difficulty / isEnglishOnly / tags / relatedTerms）
- [x] terms.zh-TW.json 對應翻譯（definition / example / memoryHook，status: verified）
- [x] 驗證 0 missing / 0 extra（另檢查 category 與 relatedTerms 引用完整）

**工時**：3 小時（含查資料 + 翻譯 + 例句）

**Claude Code prompt**：
> 根據 Anthropic 官方 docs.claude.com 與 Claude Code 文件，補 30 個高頻 CC 術語進 terms.en.json + terms.zh-TW.json，照 schema v2 寫好 isEnglishOnly 與 difficulty。完成後跑驗證腳本。

---

### 2.2 terms.json schema 加 `realUse` 與 `commonConfusion`
**狀態**：✅ DONE (2026-05-20)
**為何**：學習效果可再翻倍（FRIENDLY_LEARNING.md §4.1 提過）
**Acceptance**：
- [x] LocalizedTranslation 加兩個 optional String 欄位
- [x] 全部 60 個詞填好 `realUse`（真實用法片段；ROADMAP 原訂「≥30」）
- [x] 15 個易混淆詞填 `commonConfusion`（原訂「≥10」）
- [x] TermDetailView 加兩個 Block（「真實用法」+「⚠️ 容易混淆」），6 語系加對應 i18n key

**工時**：4 小時

---

## 3. v0.7 — Visual Assets

### 3.1 App Icon 1024×1024
**狀態**：✅ DONE (2026-05-20)
**為何**：上架必要
**實作**：`tools/render_icon.swift`（macOS `swift` + SwiftUI `ImageRenderer`，純 CLI）渲染簡化版 Lexi owl → 1024² PNG（RGB 無 alpha）。
**Acceptance**：
- [x] PNG 1024×1024
- [x] 紫漸層背景 + Lexi 圖像（簡化版）
- [x] iOS Asset Catalog（`Assets.xcassets/AppIcon.appiconset`，單一 universal 1024；Xcode build 時自動生其餘尺寸）

**工時**：2 小時（如自己畫）/ 30 分（如外包 Fiverr）

**Claude Code prompt**：
> 用 SwiftUI shape 在 LexiView.swift 寫一個 `LexiIcon` 變體（沒動畫、無背景），然後用 `ImageRenderer` API render 成 1024×1024 PNG 存到 outputs/。

---

### 3.2 App Store 截圖 ×6 (en + zh-TW)
**狀態**：✅ DONE (2026-05-21)
**為何**：上架必要
**畫面清單**：對齊 `APPSTORE_METADATA.md` §截圖 Tagline = Today / Detail / Quiz / Browse / Settings / Dark mode（本節原誤寫 AI Boost / Listen Mode；tagline 文案是針對 Settings/Dark 寫的，以 METADATA 為準）。
**實作**：
- `ScreenshotHarness.swift` — DEBUG-only（`#if DEBUG`，Release 編譯時剔除），由 launch arg 驅動把指定畫面直接當 root、跳 onboarding、設語系/主題。
- `tools/shoot_screenshots.sh` — boot iPhone 17 Pro Max（6.9"）、build Debug、`simctl` 迴圈 6 畫面 × en/zh-TW 截 12 張 raw。
- `tools/render_screenshots.swift` — `ImageRenderer` 疊品牌紫漸層 + tagline headline。
- 產出 `outputs/screenshots/{en,zh-TW}/`（gitignore；scripts 為 SoT，可重生）。

**Acceptance**：
- [x] iPhone 6.9" 6 張：Today / Detail / Quiz / Browse / Settings / Dark mode（1320×2868）
- [x] en 版（英文 UI + es 詞庫內容 — `terms.en.json` 是主檔無翻譯，en 內容會是 placeholder）+ zh-TW 版
- [x] tagline overlay（品牌漸層 + headline，見 APPSTORE_METADATA.md）
- [ ] 上傳 App Store Connect（待 §6.2 送審階段）

**工時**：3 小時

---

## 4. v0.8 — TestFlight Beta

> §4.2 / §4.4 的 App Store Connect 後台逐步操作見 [APPSTORE_CONNECT_SOP.md](./APPSTORE_CONNECT_SOP.md)。

### 4.1 Apple Developer Program 申請
**狀態**：✅ DONE — 帳號已啟用
**Apple 帳號筆記**：
- 帳號型態：Individual／台灣 → **App Store 賣家名稱會顯示法定真名**
- iOS 26 SDK 最低要求（2026-04-28 起強制上傳）：AgenticLex 已用 Xcode 26.5 / iOS 26.5 SDK build，**已符合**
- Age rating：Apple 新制把「AI 助理／chatbot」納入分級；AgenticLex 有 Ask Lexi（BYOK AI 對話），App Store Connect 填分級時**不一定能維持 4+**，照問卷誠實作答
- Team ID／簽章帳號等敏感資訊不入公開倉，build 為自己 device 時填入 `project.yml` 的 `DEVELOPMENT_TEAM`
**Acceptance**：
- [x] 信用卡 USD $99/yr 完成付款
- [x] developer.apple.com 顯示 Active

---

### 4.2 In-App Purchase × 3 (Tip Jar) 在 App Store Connect
**狀態**：🟡 進行中
**Acceptance**：
- [ ] `com.gotman.agenticlex.tip.small` ($0.99 Consumable)
- [ ] `com.gotman.agenticlex.tip.medium` ($4.99 Consumable)
- [ ] `com.gotman.agenticlex.tip.large` ($19.99 Consumable)
- [ ] Status: Ready to Submit
- [ ] 每個 IAP 填好 description（en + zh-TW）
- [x] Review screenshot — Tip Jar 三態修復後重拍，3 個 tier（$0.99 / $4.99 / $19.99）正常顯示，一張三個 IAP 共用（2026-05-21）

**工時**：1 小時

---

### 4.3 Privacy Policy / Support URL GitHub Pages
**狀態**：✅ DONE — 已部署上線 (2026-05-20)
**實作**：`site/` 寫 `privacy.md` / `support.md` / `index.md`（英文，反映 0 蒐集 / 0 追蹤 / BYOK disclose）；部署到 public repo `gotman888/agenticlex-docs` 的 GitHub Pages。
**上線 URL**（之後填 App Store Connect 用）：
- Privacy Policy：`https://gotman888.github.io/agenticlex-docs/privacy`
- Support：`https://gotman888.github.io/agenticlex-docs/support`
**Acceptance**：
- [x] Privacy Policy / Support 文案撰寫
- [x] repo `gotman888/agenticlex-docs`（public）啟用 GitHub Pages
- [ ] 兩個 URL 填進 App Store Connect（待 §6.1 metadata 階段）

**工時**：30 分

**Claude Code prompt**：
> 幫我寫一份極簡的 Privacy Policy（給 AgenticLex iOS app），內容反映：0 蒐集、0 追蹤、BYOK 部分明確 disclose。然後我會手動 commit 到 GitHub。

---

### 4.4 TestFlight 內測
**狀態**：🟡 內測中 — build 已上 TestFlight、Internal Tester 邀請已發出（2026-05-21）
**已完成（簽章階段，commit `f18b4bb` / 2026-05-21）**：
- `project.yml`：app target 加 `DEVELOPMENT_TEAM: YOUR_TEAM_ID` + `CODE_SIGN_STYLE: Automatic`，移除 simulator-only 的 `CODE_SIGNING_ALLOWED/REQUIRED: NO`
- `MARKETING_VERSION` 0.5.0 → 1.0.0（TestFlight 與正式上架共用同一版號，之後只 bump `CURRENT_PROJECT_VERSION`）
- `xcodegen generate` 重生 project，simulator build 驗過 BUILD SUCCEEDED

**已完成（Apple 後台，2026-05-21 — 王宏盟手動，逐步見 [APPSTORE_CONNECT_SOP.md](./APPSTORE_CONNECT_SOP.md)）**：
- developer.apple.com 註冊 App ID `com.gotman.agenticlex`
- App Store Connect 建 App 記錄
- Xcode Archive → Distribute → Upload（build 已上 TestFlight）
- TestFlight Internal Testers 設定（邀請信已發出）

**備註 — 實機安裝測試暫緩（2026-05-21 決定）**：
build `1.0.0 (1)` 在 App Store Connect 狀態為「準備提交」＝已處理、有效。
但 TestFlight app 實機安裝跳「要求的 App 無法使用或不存在」；研判為 TestFlight
散佈設定問題（最可能：tester 在 External 群組、build 未過 Beta App Review），
**非程式 / binary 問題**。王宏盟決定不急著測安裝 —— build 有效即達 §4.4 里程碑、
§6.2 送審不以實機測試為硬門檻。日後要測：改用 **Internal Testing** 群組（免 Beta
審核、馬上可裝），把 build 加進內部群組即可。**勿再重查此 install 問題。**

**Acceptance**：
- [x] Build upload 成功
- [ ] 3 個朋友裝起來，沒 crash 就好
- [ ] 收 5 條以上 feedback

**工時**：3 小時 first time setup

---

### 4.5 TestFlight 公測
**狀態**：⚪ TODO
**Acceptance**：
- [ ] Public TestFlight link 開放
- [ ] X / r/ClaudeAI 各發一篇邀人
- [ ] 100 人安裝目標

**工時**：1 小時

---

## 5. v0.9 — Localization Push

### 5.1 ja/ko AI 翻譯 + 母語審校
**狀態**：🟡 進行中 — AI 翻譯完成（2026-05-21），待母語審校
**為何**：v1.0 開放 ja/ko 兩個額外語系
**已完成（AI 翻譯，commit `dcb3b46` / 2026-05-21）**：`terms.ja.json` / `terms.ko.json` 各 60 詞全翻（超出原訂「30+」），完整 6 欄位（term / definition / example / memoryHook / realUse + commonConfusion×15），與 zh-TW 對等；`translator: "claude-opus-4-7"`（非原 prompt 的 sonnet）。
**Acceptance**：
- [x] terms.ja.json AI 翻 60 詞（> 原訂 30+），標 `status: "ai"`
- [x] terms.ko.json 同上
- [ ] 找 1 個 ja native + 1 個 ko native 友人審 → 改 `status: "verified"`
- [x] terms.en.json metadata.fullyTranslatedLocales 加 `ja`, `ko`

**工時**：5 小時（含翻譯 + 等審回）

**Claude Code prompt**：
> 讀 terms.en.json 與 terms.zh-TW.json，把 zh-TW 翻譯整批 AI 翻成 ja 與 ko，產出 terms.ja.json 與 terms.ko.json（每筆標 status: "ai", translator: "claude-sonnet-4-6"）。

---

### 5.2 es/pt 同上
**狀態**：🟡 進行中 — AI 翻譯完成（2026-05-21），待母語審校
**已完成（AI 翻譯，commit `383a199` / 2026-05-21）**：`terms.es.json` / `terms.pt.json` 各 60 詞全翻，完整 6 欄位，標 `status: "ai"`；`terms.en.json` 的 `fullyTranslatedLocales` 補齊全 6 語系。詞庫內容在 en / zh-TW / ja / ko / es / pt 已 100% 覆蓋。
**待辦**：找 es native + pt native 友人審 → 改 `status: "verified"`。
**工時**：5 小時

---

## 6. v1.0 — App Store Launch

### 6.1 App Store metadata 填好
**狀態**：✅ 完成（2026-05-24）— ⚠️ 修正：2026-05-21 此處原寫「6 語系文案已填入 ASC」，2026-05-24 進 ASC 實際一看是**空的**，由 Cowork 代操補填。v1.0 決定**只上英文 listing**（繁中等其他語系之後再開）。英文文案（描述/關鍵字/行銷文字/支援 URL/版權）+ 英文截圖 6 張已上傳 ASC。
**已完成**：
- 文案定稿（commit `37c6f24` / 2026-05-21）：`docs/APPSTORE_METADATA.md` 6 語系 App Name / Subtitle / Keywords / Description / Promotional Text 全部備妥；subtitle 已移除 "Claude Code" 商標；詞數更新為 60；Notes to Reviewer（含 BYOK 說明）寫成可貼段落。
- 王宏盟已將上述 6 語系文案 + Notes to Reviewer 貼入 App Store Connect（2026-05-21）。
**Acceptance**：
- [x] App Name / Subtitle / Keywords / Description / Promotional Text 全部填入 App Store Connect
- [ ] 截圖上傳 en + zh-TW（其他語系沿用 en）— §3.2 已產出 12 張於 `outputs/screenshots/`，待送審階段上傳 ASC
- [x] Notes to Reviewer 含 BYOK 說明

**工時**：2 小時

---

### 6.2 Submit for Review
**狀態**：🟡 就緒（2026-05-24）— ASC 版本頁全綠、build 1.0.0(4) 已掛、「新增以供審查」鈕已亮，等王宏盟親按 Submit（不可逆動作由本人按）。送審流程問 IDFA / 廣告識別碼答「否」。
**Acceptance**：
- [ ] 按「新增以供審查」→ Submit（build 1.0.0 (4)）
- [ ] 等 Apple 1-3 天審核
- [ ] 過審 → 自動上架（已設供應 175 國；非先 Taiwan，v1.0 改全球）

**工時**：30 分 submit + 1-3 天等

---

### 6.3 Taiwan 軟啟動觀察 7 天
**狀態**：⚪ TODO
**Acceptance**：
- [ ] App Store Connect Analytics 看下載
- [ ] Crash-free rate > 99.5%
- [ ] Reviews 至少 1 條 4 星以上

**工時**：每天 5 分鐘看數據

---

### 6.4 全球釋出
**狀態**：⚪ TODO
**Acceptance**：
- [ ] App Store Connect → Pricing → Availability → 全選 165 國
- [ ] 寫 1 篇中英 blog post
- [ ] 投 Hacker News + Reddit r/ClaudeAI

**工時**：3 小時

---

## 7. v1.1+ 之後（Backlog）

按 `docs/OPTIMIZATION.md` 與 `docs/FRIENDLY_LEARNING.md` 列的 P2 / P3：

- ✅ 🎤 Shadow Read（跟讀 + 語音辨識）— DONE (2026-05-21)：`ShadowReadView` 多詞連續跟讀 session（intro → 每詞 聽範讀 → 錄音 → 評分 → summary）。`Services/SpeechRecognizer.swift` 包 `SFSpeechRecognizer` + `AVAudioEngine`，**強制裝置端辨識**（`requiresOnDeviceRecognition`，音訊不外流；不支援則友善停用）。評分用正規化 + Levenshtein 容錯、失敗暖色不用紅。TodayView 全寬入口；Info.plist 加麥克風 + 語音辨識用途字串（7 語系 `InfoPlist.strings`）；7 語系加 15 個 `shadow.*` key。實際辨識待裝置自測
- ✅ 🗺️ Concept Map — DONE (2026-05-21)：`ConceptMapView` 可走訪詞彙關聯圖（中心詞 + `relatedTerms` 衛星 + 連線，`GeometryReader` 圓周座標 + `Path`）；點衛星走訪、點中心開詳情。`TermDetailView` 加入口；純 SwiftUI、無物理引擎、iOS 16 相容
- ✅ 📤 Share Card — DONE (2026-05-21)：`TermDetailView` 導覽列分享一張 1080² 品牌圖卡（`ShareCardView` + `ImageRenderer` 離屏渲染 + `ShareLink` 叫 iOS 原生分享面板）；任何詞可分享、無後端、iOS 16 相容
- ✅ 🔔 Daily streak notification — DONE (2026-05-21)：`NotificationService` + Settings 開關／時間，本機排程、無後端
- ✅ 🌙 修 Today/Detail 深色模式 — DONE (2026-05-21)：`AppColor` 加 `Color.adaptive(light:dark:)`（`UIColor` dynamic provider），8 處寫死淺色 token 改 light/dark 雙值。§3.2 Dark 截圖目前仍用 Settings 畫面，Today/Detail 已可改回（需要再決定）
- ⌚️ Apple Watch widget
- ✅ 🗣️ Siri Shortcuts — DONE (2026-05-21)：App Intents（iOS 16+）2 個 intent — 今日單字→Today tab、聆聽模式→push Listen Mode；`AppShortcutsProvider` 自動註冊，零 Apple 後台設定、無 entitlement。新增 `Services/AppRouter.swift`（singleton 橋接導航）+ `App/AppShortcuts.swift`；`ContentView` TabView 加 selection binding（4 tab 不變）、7 語系加 4 個 `siri.*` key。Siri 語音片語 7 語系齊
- ✅ 📚 Learning Path levels — DONE (2026-05-21)：`LearningPathView` 依 `difficulty` 分 3 級（基礎 18 / 核心概念 32 / 進階 10）的垂直學習旅程 — 軌道連線 + 級別卡（進度條 + X/Y 已學會 + 完成打勾）、Lexi 站目前級別、**友善不鎖**。點級別 → 該級詞彙清單 → 詞詳情。進度即時由 `ProgressStore` 算、無新持久化；Browse 導覽列入口、7 語系加 8 個 `path.*` key。純 SwiftUI、iOS 16 相容
- ✅ 🌐 zh-CN locale — DONE (2026-05-21)：第 7 語系 简体中文。`terms.zh-CN.json` 60 詞（由 verified 的 zh-TW 在地化成陸用語，`status: ai` 待母語審校）+ `zh-Hans.lproj` 174 keys + `AppSettings` 加 `zh-Hans→zh-CN` 分流；7 語系 174 keys × 7 一致、build SUCCEEDED
- ✅ 🔄 OTA 詞庫更新 — DONE (2026-05-21)：opt-in 詞庫線上更新。`Services/TermUpdateService.swift` 查遠端 `terms.en.json` 版本、較新才下載 7 個 term JSON 到 Documents；`TermStore` OTA-aware（優先 Documents、app 更新時自清）。Settings「DATA」加開關（**預設關**），純靜態 GitHub raw、無 server / 無 tracking。⚠️ 需用戶把 `terms.*.json` 發佈到 `gotman888.github.io/agenticlex-docs/dict/` 才會生效（未發佈前 dormant）；7 語系加 6 個 `settings.dict.*` key
- ✅ 🎙️ AI Chat streaming（SSE）— DONE (2026-05-21)：Ask Lexi 回答改 SSE token-by-token 串流（`AIChatService.stream` + `URLSession.bytes`，Claude / OpenAI / Gemini 三 provider），thinking bubble 只在首 token 前顯示；無新檔、無 i18n、iOS 16 相容
- ✅ 📮 回饋改善機制 + 開源 — DONE (2026-06-03)：device-only 三層回饋——in-app `MailComposer`（預填診斷的回饋信，取代 raw mailto）+ TermDetail 逐詞「回報/建議翻譯」+ `status:ai` AI 翻譯 badge + QuizResult 評分提示（streak≥3 & mastered≥10、每版 1 次）；ops `docs/FEEDBACK_OPS.md` 三門 triage SOP + `tools/fetch_reviews.py`（唯讀 ASC 評論抓取，跑 owner Mac、不進 app）。**落實 A9 開源**：公開 repo `github.com/gotman888/AgenticLex`（MIT / CC-BY、curated 快照），修掉指向不存在 repo 的死連結（§4.4 / §6.3 兩條 feedback 驗收終於有機制）。OTA「we listened」閉環待 `dict/` 發佈再做
- ✅ ✨ 上架後 polish pass — DONE (2026-06-03)：Quiz 去紅(hug/leaf)、英文錨點 rounded、`brandPrimary` adaptive、Browse/LearningPath 暖底、深色漏網修補、translation tint、padding 歸格、Browse 空搜尋 Lexi、Gemini URL crash 修、SpeechService 去 per-word 重繪、SpeakerButton 44pt、haptic 補齊、Lexi/ConceptMap a11y。**收尾完成**（2026-06-03，經 11-agent 對抗式 review）：原 deferred 全做完——ProgressStore off-main 寫入 + scenePhase background `flush()`、TermStore 啟動 pre-warm（fallback `autoDetectLocale`）、AskLexi 串流 throttle + 中途錯誤保留 partial、TodayView `pickedTerms` hoist；TermRow `.blue` → brand tokens 並同步 `DESIGN.md:111` 圖例。OTA「we listened」謝謝行就緒（待 `dict/` 發佈才亮）

---

## 8. 用 Claude Code 跑 ROADMAP 的標準流程

每次開新 task：

```
1. cd ~/Code/ClaudeCodeLex && claude
2. 對 Claude 說：
   「我要做 v0.5.1 — 清理 unused i18n keys。
    請依 docs/ROADMAP.md §1.1 列計畫讓我確認。」
3. Claude 提計畫 → 你 confirm → Claude 動手
4. 改完 Claude 跑驗證腳本 → 報結果
5. 你 ⌘R 跑 simulator 看效果
6. 改下一個 task
```

---

End of ROADMAP.md
