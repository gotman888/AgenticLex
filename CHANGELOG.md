# Changelog

All notable changes to AgenticLex are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) · Semver.

---

## [1.0.0] - 2026-05-31 — 🎉 App Store 首版上架

- **🎉 AgenticLex 1.0.0 (build 5) 過審上架** — App Store URL: https://apps.apple.com/app/agenticlex/id6771639472
- 上架歷程：3 輪 review、5/31 第三輪 resubmit (純後台 fix, 無 build 6) → 5/31 APPROVED。退審重點：5.1.1(i)/5.1.2(i) third-party AI 揭露、2.1(b) IAP 載入
- **上架時 build = 1.0.0 (5)**, build 4 因首輪 reject 被 build 5 替換
- **3 個 IAP** (com.gotman.agenticlex.tip.small/medium/large) 全部上架
- **Small Business Program** enrollment → commission 30% → 15%

## [Unreleased]

> **詞庫 v2.14.0 — zh-TW 全量審校（2026-06-05）**：王宏盟逐條核可 backfill 的 163 個 zh-TW 翻譯，`status: ai → verified`（60→**223 全 verified**，AI badge 自此於 zh-TW 全數消失）；`translator` 保留 `claude-opus-4-8`（AI 起草、人工核可＝verified 戳章）。en `metadata.version` 2.13.1→2.14.0。其餘 5 語系（zh-CN/ja/ko/es/pt）維持 `ai` 待審。**follow-up**：重發 OTA `dict/` 到 `agenticlex-docs`，已 opt-in 用戶才會收到 verified 版。

> **v1.1.x — 上架後 polish + 回饋機制 + 開源（2026-06-03，6 commit，每批 build SUCCEEDED、i18n 241×7 一致）**
> ① 開源 / 修死連結：建公開 repo `github.com/gotman888/AgenticLex`（MIT code / CC-BY 內容、由私有倉 curated 出的 fresh-repo 快照）落實 `OPTIMIZATION.md` A9；App Store 描述 + in-app 原指向不存在的 `github.com/gotman888/AgenticLex`（404）—建 repo 後生效；`SettingsView` mailto subject + GitHub 連結正名為 AgenticLex（移除 code-name 洩漏）；`plugin` 詞條例句改用通用範例 `git-pro`（6 語系；連 build 5 都含、下版上架清掉殘留）。
> ② 美化：Quiz 答題回饋去紅（`Color.red/.green`→`AppColor.hug/.leaf`，貫徹「答錯永不紅」）；英文錨點字體 `.system`→`.rounded`（Detail hero 56 / translation 22、Quiz 題 36、TermCardMini 18 / TermRow 16）；`AppColor.brandPrimary` 改 adaptive（#7C5BFF / #A48BFF，對齊 DESIGN.md）；Browse + LearningPath 詞列補暖色底（`.scrollContentBackground(.hidden)` + `warmBg`）；深色模式漏網修補（ListenMode 速度卡、AskLexi 輸入框 `Color.white`→adaptive）；TermDetail translation block 紫 tint 連結 hero；卡片 padding 14/18→16 歸格；Quiz 答題 tile 進場 `withAnimation`；BYOK 測試失敗圖示/色柔化（`xmark.octagon`→`exclamationmark.circle`、red→hug/leaf）；Browse 空搜尋 Lexi 空狀態（+`browse.noResults` ×7）。
> ③ 回饋機制（device-only 三層、無後端/無追蹤）：**in-app** — 新 `MailComposer`（`MFMailComposeViewController`，預填 app/build/iOS/裝置/UI+native locale/字典版本，無 Mail 帳號 fallback mailto）取代 raw mailto、`TermDetailView` 逐詞「回報問題/建議翻譯」鈕（預填 term 上下文）、`status:"ai"` 翻譯加「AI translation — not yet reviewed」badge、`QuizResultView` 高點觸發系統評分提示（`@Environment(\.requestReview)`，gate streak≥3 & mastered≥10、每版 1 次，新 `ReviewPrompter` + `AppSettings.ratingPromptedVersion` + `ProgressStore.masteredCount`）；+4 i18n key ×7（`feedback.subject` / `report.intro` / `detail.report` / `detail.aiTranslation`）。**ops（不進 app）** — `docs/FEEDBACK_OPS.md` 三門 triage SOP + `tools/fetch_reviews.py`（唯讀 App Store Connect customerReviews，ES256 JWT、watermark）+ launchd 週排程 template。OTA「we listened」閉環 deferred（`dict/` 未發佈）。
> ④ 優化：修 Gemini streaming URL force-unwrap **crash**（`URLComponents` + percent-encode 貼上的 key）；`SpeechService.currentRange` 去 `@Published`（無 view 讀的 karaoke 殘留）停掉每唸一字重繪所有 SpeakerButton 的 objectWillChange storm；SpeakerButton 觸控區→≥44pt（HIG，視覺仍 28）；Quiz 答錯 `.warning` + ShadowRead 評分三段 haptic；Lexi `.accessibilityHidden`（裝飾退出 VoiceOver）、ConceptMap 衛星改 Button（VoiceOver 可達 + 44pt，複用 `conceptMap.hint`）。（以下原列 deferred，已於收尾全數完成 → 見 ⑤）
> ⑤ 收尾完成（2026-06-03，經 11-agent 對抗式 review 修耐久性/串流邊界）：`ProgressStore` 寫入改 off-main serial queue + scenePhase `.background` `flush()`（保 streak 耐久，不掉最後一筆）；`TermStore` 啟動 pre-warm 母語 locale（fallback `autoDetectLocale()`，首次啟動也生效）；`AskLexiView` 串流改本地 buffer + ~60ms throttle（O(n²)→O(n)）+ 中途錯誤保留 partial 文字；`TodayView` `pickedTerms` 一次算（5×→1×）；TermRow 狀態點 `.blue/.orange/.green` → brand tokens（紫/橙/綠，+ `DESIGN.md` 圖例同步）；OTA「we listened」謝謝行（`settings.dict.thanks` ×7，dict 發佈後亮）。

> v0.5 — Polish & Cleanup 程式碼全部完成（5/5），均過腳本驗證（i18n / terms / 邊界稽核）；
> 首次 Xcode build 已驗證：`xcodegen` 生成 project → `xcodebuild` **BUILD SUCCEEDED**，9 個 unit test 全綠。
> v0.6 — Content Expansion 完成：詞庫 30→60（§2.1）+ terms schema 加 realUse / commonConfusion（§2.2），build 與 i18n 驗證通過。
> v0.7 — Visual Assets 進行中：App Icon 1024² 已生成並接上 build（§3.1），§3.2 截圖待辦。
> v0.8 — TestFlight 準備：Apple Developer 帳號啟用（§4.1）；Privacy Policy / Support 已寫並部署上線（§4.3）；
> 發佈簽章設定完成、版號定 1.0.0（§4.4 簽章階段），剩 App Store Connect 後台 IAP ×3 與 build 上傳。
> v0.9 — Localization Push：詞庫 ja/ko（§5.1）+ es/pt（§5.2）AI 翻譯完成，6 語系內容 100% 覆蓋；待母語審校轉 verified。
> v1.0 — App Store 上架準備：修好 Tip Jar IAP 在模擬器永遠轉圈的問題（scheme 接 StoreKit 設定、載入失敗改「可重試」狀態），Tip Jar 命名對齊 ASC。
> v1.1 — Backlog 起步：每日 streak 提醒通知（ROADMAP §7）—— 本機 `UNUserNotificationCenter` 排程、Settings 可開關與設定時間、無後端。
> v0.7 — §3.2 App Store 截圖補完：DEBUG-only 截圖 harness + `tools/` 自動化 pipeline 產出 6 畫面 × en/zh-TW 共 12 張 1320×2868 marketing 截圖。
> v1.1 — 修 Today/Detail 深色模式破圖（ROADMAP §7）：8 處寫死淺色 token 改 adaptive。
> v1.1 — 新增 zh-CN（简体中文）第 7 語系（ROADMAP §7）：詞庫 + UI 字串 + locale 接線，7 語系內容 100% 覆蓋。
> v1.1 — Share Card（ROADMAP §7）：TermDetailView 導覽列分享一張品牌圖卡（`ImageRenderer` 離屏渲染 + `ShareLink`），無後端、iOS 16 相容。
> v1.1 — AI Chat 串流（ROADMAP §7）：Ask Lexi 回答改 SSE token-by-token 即時長出，三 provider 全支援。
> v1.1 — Concept Map（ROADMAP §7）：TermDetailView 進入可走訪的詞彙關聯圖，點節點遍歷關係。
> v1.1 — Concept Map 橢圓佈局：原圓形佈局在窄長手機飄小、上下大量留白，改 `radiusX` 寬綁定 / `radiusY` 吃垂直高度 + 中心上下平衡，圖填滿畫面。
> v1.1 — Siri Shortcuts（ROADMAP §7）：App Intents 2 intent（今日單字→Today / 聆聽模式→Listen Mode），開 app + 導航；零 Apple 後台設定、無 entitlement。
> v1.1 — Learning Path（ROADMAP §7）：依 difficulty 分 3 級的垂直學習旅程，友善不鎖、Browse 導覽列入口。
> v1.1 — Shadow Read（ROADMAP §7）：多詞跟讀 session，裝置端語音辨識評分、不焦慮回饋。
> v1.1 — 補齊 7 語系缺口：權限用途字串（InfoPlist.strings）+ Siri 語音片語全 7 語系在地化。
> v1.1 — OTA 詞庫更新（ROADMAP §7）：opt-in 詞庫線上更新，Settings 開關預設關、純靜態 GitHub raw、無 server。
> v1.0 — App Store 送審就緒（2026-05-24）：Cowork 代操 App Store Connect 走完 IAP×3 / 截圖 / 文案 / Privacy / Age Rating 4+ / 定價免費 / 供應 175 國，版本頁全綠等王宏盟親按 Submit。**改 iPhone-only**（`project.yml` `TARGETED_DEVICE_FAMILY` `1,2`→`1`）解 Universal 缺 iPad 截圖擋送審；**修 App Intents 90626 Invalid Siri**（`AppShortcuts.swift` 兩個 `IntentDescription` 改乾淨英文字面字串，不用含 "siri" 的 localization key；`siri.wotd.desc` / `siri.listen.desc` 這 2 個 key 在 7 語系 strings 檔變成未使用，依紅線保留不刪）；ASC 描述欄移除 ❤️ emoji（無效字元）；build 1→4（2、3 失敗各燒一個號）。完整踩雷與真實流程見 `docs/APPSTORE_CONNECT_SOP.md` 頂端「v1.0 上架實戰總結」。

### Added
- **Views/ReviewSessionView.swift** — 從 `QuizView.swift` 抽出 `ReviewSessionView`（複習連播畫面）
- **Tests/ProgressStoreTests.swift** — `ProgressStore` SRS 狀態機 9 個 unit test（new→learning / learning→reviewing / wrong→new / streak 等）
- **Reduce Motion 支援** — `LexiView`（reduce motion 時停浮動/眨眼）+ `CelebrationView`（confetti 改 fade-in），讀 `accessibilityReduceMotion`
- **Quiz 答對即時慶祝** — `QuizCardView` 答對觸發 `QuickConfetti`（非 modal 撒花 ~0.5s）+ haptic `.success`；答錯時 Lexi `.hug` 浮現 1s。`CelebrationView.swift` 新增 `QuickConfetti` 元件
- **project.yml** — XcodeGen spec，CLI 跑 `xcodegen generate` 一鍵生成 `ClaudeCodeLex.xcodeproj`（bundle id `com.gotman.agenticlex`、iOS 16、排除 `terms.json` stub、Info.plist 設 `AgenticLex` / `UIBackgroundModes:audio` / Portrait）
- **詞庫擴充 30 → 60**（v0.6 §2.1）— 新增 30 個 agentic coding 術語（cli +4 / hooks +3 / mcp +3 / sub-agent +3 / plugins +2 / skills +2 / artifacts +2 / tools +5 / context +2 / prompting +4），`terms.en.json` + `terms.zh-TW.json` 雙檔同步，全部 `status: verified`
- **terms schema `realUse` / `commonConfusion`**（v0.6 §2.2）— `LocalizedTranslation` 加兩個 optional 欄位；填 `realUse`（真實用法片段）×60、`commonConfusion`（易混淆對照）×15；`TermDetailView` 加「真實用法」與「⚠️ 容易混淆」兩個 Block；6 語系加 `detail.realUse` / `detail.commonConfusion`
- **App Icon**（v0.7 §3.1）— `tools/render_icon.swift`（macOS `swift` + SwiftUI `ImageRenderer`）渲染簡化版 Lexi owl 成 1024² PNG（紫漸層底、RGB 無 alpha）；新增 `Assets.xcassets/AppIcon.appiconset`（單一 universal entry）；`project.yml` 設 `ASSETCATALOG_COMPILER_APPICON_NAME`
- **Privacy Policy / Support 頁**（v0.8 §4.3）— `site/` 新增 `privacy.md` / `support.md` / `index.md`（英文）+ 部署說明 `README.md`；反映 device-only、0 蒐集、0 追蹤、BYOK 明確 disclose。已部署到 `gotman888.github.io/agenticlex-docs`（GitHub Pages）
- **docs/APPSTORE_CONNECT_SOP.md** — v0.8 App Store Connect 後台操作 SOP（IAP ×3 product 對照、簽章、TestFlight 上傳、Age Rating / Privacy / Notes to Reviewer）
- **詞庫多語系翻譯**（v0.9 §5.1 / §5.2）— 新增 `terms.ja.json` / `terms.ko.json`（§5.1）+ `terms.es.json` / `terms.pt.json`（§5.2），各 60 詞、完整 6 欄位（term / definition / example / memoryHook / realUse + commonConfusion×15），`status: "ai"`、`translator: "claude-opus-4-7"`；`terms.en.json` 的 `fullyTranslatedLocales` 補齊全 6 語系。詞庫內容在 en / zh-TW / ja / ko / es / pt 已 100% 覆蓋，待母語審校轉 `verified`
- **每日 streak 提醒通知**（v1.1 §7）— 新增 `Services/NotificationService.swift`（`UNUserNotificationCenter` 包裝：授權請求 + 每日 repeating 排程）；`SettingsView` 加 NOTIFICATIONS section（開關 Toggle + 時間 DatePicker）；`AppSettings` 加 `dailyReminderEnabled` / `reminderHour` / `reminderMinute`；`ClaudeCodeLexApp` 在 app 轉 active 時用當前 streak 重排，讓通知文案 streak > 0 顯示連續天數。純 device-only、無後端、無 push token。6 語系加 6 個 i18n key
- **App Store 截圖 pipeline**（v0.7 §3.2）— 新增 `App/ScreenshotHarness.swift`（**DEBUG-only**，`#if DEBUG` 包整檔、Release 剔除；由 launch arg 把指定畫面直接當 root、跳 onboarding、設語系/主題）+ `tools/shoot_screenshots.sh`（boot iPhone 17 Pro Max、build Debug、`simctl` 迴圈截 6 畫面 × en/zh-TW）+ `tools/render_screenshots.swift`（`ImageRenderer` 疊品牌漸層 + tagline）。產出 `outputs/screenshots/{en,zh-TW}/` 共 12 張 1320×2868 PNG（App Store 6.9" 規格）。`ContentView` / `ClaudeCodeLexApp` 加 `#if DEBUG` harness 分支。`outputs/` 入 `.gitignore`（scripts 為 SoT、可重生）
- **zh-CN（简体中文）第 7 語系**（v1.1 §7）— 新增 `Resources/terms.zh-CN.json`（60 詞、完整 6 欄位、`status: "ai"`、`translator: "claude-opus-4-7"`，由 verified 的 zh-TW 在地化成陸用語：程式→程序、檔案→文件、介面→接口/界面、快取→缓存、物件→对象等）+ `Resources/zh-Hans.lproj/Localizable.strings`（174 keys）。`AppSettings` 的 `supportedLanguages` 加 `简体中文`、`autoDetectLocale` 加 `zh-Hans→zh-CN` 分流（修正簡中裝置原誤判成 zh-TW）；`terms.en.json` metadata `supportedLocales` / `fullyTranslatedLocales` 與 11 個 category `names` 補 zh-CN。XcodeGen 自動納入 `zh-Hans` knownRegion，詞庫內容 7 語系 100% 覆蓋
- **Share Card 分享圖卡**（v1.1 §7）— 新增 `Views/Components/ShareCardView.swift`（1080×1080 品牌圖卡：紫漸層 + 英文詞 hero + IPA + 母語翻譯 + 定義 + Lexi + AgenticLex wordmark，固定淺色不受深色模式影響）+ `ImageRenderer` 離屏渲染成 `UIImage` 的 `renderImage()` helper。`TermDetailView` 導覽列加 `ShareLink` 分享鈕（`.onAppear` 預渲染卡片成 `Image`、附 `SharePreview`），叫出 iOS 原生分享面板（Messages / IG / 存相簿 / AirDrop）。7 語系加 `detail.share`。純 device-only、iOS 16 相容
- **Concept Map 概念圖**（v1.1 §7）— 新增 `Views/ConceptMapView.swift`：可走訪的詞彙關聯圖，中心為當前詞、`relatedTerms` 環繞為衛星節點並以連線相接（`GeometryReader` 橢圓座標：`radiusX` 由螢幕寬綁定、`radiusY` 吃垂直空間、中心點依節點分布上下平衡，讓圖填滿窄長手機；`Path` 連線，純 SwiftUI 幾何、無物理引擎）。點衛星 → 該詞 crossfade 成新中心（遍歷整張圖）、點中心 → 開該詞詳情。`TermDetailView` 在 `relatedBlock` 後加入口（gated on `!relatedTerms.isEmpty`）。7 語系加 `conceptMap.title` / `conceptMap.hint`
- **驗收 harness 擴充**（v1.1）— `ScreenshotHarness` 加 `sharecard` / `conceptmap` 兩個 DEBUG-only case（`#if DEBUG`、Release 剔除），可由 launch arg 把 Share Card / Concept Map 直接當 root 截圖，供 v1.1 視覺驗收用
- **Siri Shortcuts**（v1.1 §7）— App Intents（iOS 16+）2 個 intent：`WordOfTheDayIntent`（開 app → Today tab）+ `ListenModeIntent`（開 app → push Listen Mode）；`AppShortcutsProvider` 自動註冊，零 Apple 後台設定、無 Siri entitlement。新增 `Services/AppRouter.swift`（singleton 橋接 intent → 導航：`selectedTab` + `pendingDeepLink`）+ `App/AppShortcuts.swift`。7 語系加 4 個 `siri.*` key（intent 標題 / 說明）；Siri 語音片語內建英 + 繁中。純 device-only
- **Learning Path levels**（v1.1 §7）— 新增 `Views/LearningPathView.swift`：依 `difficulty` 分 3 級（基礎 18 / 核心概念 32 / 進階 10）的垂直學習旅程；軌道連線 + 級別卡（自製進度條 + X/Y 已學會 + 完成打勾）、Lexi 站在目前級別、**友善不鎖**（3 級皆可點，只標出目前焦點）。點級別 → 該級詞彙清單 → 詞詳情（closure-based 導航）。進度即時由 `ProgressStore` mastered 狀態算、無新持久化 / 無權限 / 無新 target。`BrowseView` 導覽列加入口鈕；`ScreenshotHarness` 加 `learningpath` 驗收 case。7 語系加 8 個 `path.*` key
- **Shadow Read 跟讀**（v1.1 §7）— 新增 `Services/SpeechRecognizer.swift`（包 `SFSpeechRecognizer` + `AVAudioEngine`，**強制 `requiresOnDeviceRecognition`** — 音訊不離開裝置；不支援 on-device 則友善停用、不退回 Apple 伺服器，Privacy nutrition 維持全綠）+ `Views/ShadowReadView.swift`（多詞跟讀 session：intro → 每詞 聽範讀 → 錄音 → 評分 → summary；評分正規化 + Levenshtein 容錯，失敗用暖色 + Lexi hug、不用紅）。`TodayView` 加全寬入口鈕；`project.yml` 加 `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription`（英文 v1）；`ScreenshotHarness` 加 `shadowread` case。Audio session 於畫面期間切 `.playAndRecord`、離開還原 `.playback`。7 語系加 15 個 `shadow.*` key

### Fixed
- **iOS 16 相容性** — 首次編譯抓到 2 個 iOS 17-only API：`AskLexiView` 的 `.onChange(of:initial:_:)`（雙參數 closure）改回單參數寫法；`TodayView` 的 `.navigationDestination(item:)` 改用 `.navigationDestination(isPresented:)` + optional 推導 Bool binding
- **清掉編譯 warning** — `SpeechService` 移除 no-op closure 未用的 `[weak self]` 捕獲、`CelebrationView` 移除未用的 `SystemRandomNumberGenerator` 變數；Swift warning 歸零
- **Tip Jar 永遠轉圈**（v1.0）— `Product.products()` 回空陣列卻不報錯時，`TipJarView` 只顯示 `ProgressView()` 無限轉、無錯誤無重試。`TipJarService` 加 `isLoading` 旗標；`TipJarView` 改三態（載入中 / 載入失敗+重試 / 商品清單），新增 i18n key `common.retry` + `tipjar.unavailable`（6 語系同步）
- **Today/Detail 深色模式破圖**（v1.1 §7）— `AppColor.warmBg`/`warmCard`、WOTD 卡漸層、`TermCardMini` 漸層、Detail hero / askLexi 漸層、memoryHook / commonConfusion 底色與文字共 8 處寫死淺色 `Color(hex:)`，深色模式下變白字配淺底。`AppColor` 加 `Color.adaptive(light:dark:)`（`UIColor` dynamic provider 依 `userInterfaceStyle` 回不同色），全部改 light/dark 雙值；深色保留「友善」調性（不純黑、帶微暖/紫底）

### Removed
- 14 個 unused i18n keys（11 個 `category.*` + `today.greeting` + `quiz.result.done` + `settings.disclaimer`），6 語系同步

### Changed
- `QuizView.swift` 298 → 271 行（移出 ReviewSessionView，留純 quiz 邏輯）
- 專案位置：`~/Documents/Claude/Projects/Learn-CC` → `~/Code/ClaudeCodeLex`（避 iCloud「桌面與文件」同步驅逐檔案的風險）
- **發佈簽章設定**（v0.8 §4.4）— `project.yml` app target 加 `DEVELOPMENT_TEAM: YOUR_TEAM_ID` + `CODE_SIGN_STYLE: Automatic`（Archive / TestFlight 用），移除 base 的 simulator-only `CODE_SIGNING_ALLOWED/REQUIRED: NO`
- **`MARKETING_VERSION` 0.5.0 → 1.0.0**（v0.8 §4.4）— TestFlight 與 App Store 共用同一 marketing version，後續每次上傳只 bump `CURRENT_PROJECT_VERSION`（build number）
- **scheme 接 StoreKit 設定**（v1.0）— `project.yml` scheme 的 run action 指向 `Resources/Tips.storekit`，模擬器才載得到 3 個 Tip Jar IAP（本地測試 / IAP review 截圖用；Archive 不受影響）
- **`Tips.storekit` displayName 去 emoji**（v1.0）— 對齊 ASC 無 emoji 的 IAP 名稱（避免 review 截圖雙 emoji）；`docs/APPSTORE_CONNECT_SOP.md` §4.2 同步
- **AI Chat 改 SSE 串流**（v1.1 §7）— `AIChatService` 非串流 `send` 路徑換成 `stream(...) -> AsyncThrowingStream<String, Error>`；`streamClaude` / `streamOpenAI` / `streamGemini` 用 `URLSession.bytes(for:)` 讀 SSE（Claude `content_block_delta` / OpenAI `choices[].delta` + `[DONE]` / Gemini `:streamGenerateContent?alt=sse`）。`AskLexiView` 加 `streaming` state，回答 token-by-token 即時長 bubble，thinking bubble 只在首 token 前顯示。純 device-only、iOS 16 相容（`URLSession.bytes` / `AsyncThrowingStream`）
- **ContentView TabView 加 `selection` binding**（v1.1 §7）— 為 Siri Shortcuts 導航：`TabView` 綁 `AppRouter.selectedTab`、4 個 tab 加 `.tag(AppTab)`（tab 組成不變）；`TodayView` 加 `.navigationDestination(isPresented:)` 收 `.listenMode` deep-link → push `ListenModeView`；`ClaudeCodeLexApp` 注入 `AppRouter.shared`
- **權限用途字串 + Siri 片語在地化**（v1.1）— Shadow Read 的 `NSMicrophoneUsageDescription` / `NSSpeechRecognitionUsageDescription` 改由 7 個 `<locale>.lproj/InfoPlist.strings` 在地化（原僅 `project.yml` 英文 base）；`AppShortcuts` 兩個 shortcut 的 Siri 語音片語補齊 zh-Hans / ja / ko / es / pt（原僅英 + 繁中）。權限對話框與 Siri 喚起改依裝置語言顯示
- **OTA 詞庫更新**（v1.1 §7）— 新增 `Services/TermUpdateService.swift`：opt-in 詞庫線上更新。`SettingsView`「DATA」section 加 `自動更新詞庫` 開關（**預設關**，開啟才連網）+ 狀態行；`AppSettings` 加 `dictionaryAutoUpdate`。`TermUpdateService` 查遠端 `terms.en.json` 的 `metadata.version`（dot-numeric 比較），較新才下載 7 個 term JSON 到 Documents。`TermStore` 改 OTA-aware：`resourceURL(for:)` 優先讀 Documents 下載版、否則 bundle；`purgeStaleDownloadsIfAppUpdated()` 在 app build 變動時自清舊下載（讓較新的 bundle 勝）。`ClaudeCodeLexApp` 於 scenePhase `.active` 且開關開時觸發檢查。純靜態 GitHub raw、無 server、無 tracking；遠端來源未發佈前 OTA dormant。7 語系加 6 個 `settings.dict.*` key

### Stats
- Swift files: 33 → 45（44 app + 1 test；含 DEBUG-only `ScreenshotHarness.swift`）
- Localizable keys: 178 → 210 per locale（×7，v1.1 新增 zh-Hans；v0.5 −14、v0.6 +2、v1.0 +2、v1.1 +42）
- 詞庫: 30 → 60 terms（11 categories；en / zh-TW / zh-CN / ja / ko / es / pt 7 語系 100% 覆蓋，zh-CN/ja/ko/es/pt 為 AI 翻譯待審校）

### Pending
- v0.8 — App Store Connect 設 IAP ×3、TestFlight build 上傳
- v0.9 §5.1 / §5.2 + v1.1 §7 — zh-CN / ja / ko / es / pt 詞庫母語審校（目前 `status: "ai"`）

---

## [0.4.0] — 2026-05-20 · **BYOK Edition**

> 質變版本：把 product 從「vocab app」升級成「為 AI native 設計的學習平台」。

### Added
- **Models/AIProvider.swift** — `AIVoiceProvider` (3 case) + `AIChatProvider` (3 case) + voice option metadata
- **Services/KeychainHelper.swift** — `kSecClassGenericPassword` wrapper（不存 UserDefaults）
- **Services/AIVoiceService.swift** — OpenAI TTS (`tts-1-hd`) + ElevenLabs (`eleven_turbo_v2_5`) HTTP 客戶端
- **Services/AIVoicePlayer.swift** — AVAudioPlayer 包 mp3 + lock-screen Now Playing
- **Services/AIChatService.swift** — Claude (Messages API) + OpenAI (Chat Completions) + Gemini (generateContent) 統一介面
- **Views/AIBoostView.swift** — Settings 子頁，按 provider 卡片化、key 輸入、voice/model 選、Test 按鈕、cost hint
- **Views/AskLexiView.swift** — 對話 sheet：4 個 quick prompts + 自由輸入 + thinking bubble + per-provider system prompt
- **TermDetailView** 加「💬 Ask Lexi about this」入口（僅當 chat key 已設）
- **SettingsView** 加 ✨ AI Boost NavigationLink + active badge
- **SpeechService.speak()** 接 `cloudProvider` 參數，自動 fallback to native on failure
- **6 語系 i18n** 加 36 個新 keys（aiboost.* / askLexi.* / ai.cost.*）

### Changed
- `AppSettings` 加 `voiceProviderRaw` / `chatProviderRaw` + computed property（enum 進出）
- `SpeakerButton` 自動讀 settings 用對的 cloud provider

### Security
- API keys 全走 Keychain，**0 個 key 存在 UserDefaults / file system**
- 請求 device-to-provider direct，**0 個 byte 經過 AgenticLex 後端**（因為沒有後端）

### Stats
- Swift files: 44 → 33 (+8 new for BYOK)
- Wait, 44 → was Lexi count; this is 33+? Actually:
- Total files: 44 → 52 (8 new)
- Localizable keys: 142 → 178 per locale (×6 = 1068 total)

---

## [0.3.0] — 2026-05-20 · **Friendly Edition**

> 把冷工具變成有情感的學習夥伴。

### Added
- **Views/Components/LexiView.swift** — 紫色 owl-bot 吉祥物，6 poses (wave/read/hug/cheer/wizard/sleepy)，純 SwiftUI shape、會眨眼、會浮動
- **Views/Components/CelebrationView.swift** — `CelebrationOverlay` + `ConfettiBurst` 撒花元件
- **Views/ListenModeView.swift** — 純聽連播畫面（en → 母語 → 下一個），背景播放、lock-screen 控制
- **Views/AchievementsView.swift** — 10 個徽章視覺化網格
- **Models/Achievement.swift** — `Achievement` + `AchievementSnapshot` + 10 個 hardcoded badges
- **SpeechService** 加 `SpeedTier` (slow/normal/fast) + `startListenMode([SpokenItem])` + Now Playing Info + Remote Command Center
- **TodayView** 加 Word of the Day 卡 (依日期 hash) + Random Word 按鈕 + Listen Mode 入口 + 5 種時段問候
- **AppColor** 加 warmBg/warmCard/cheer/hug/leaf 暖色 tokens
- **Font.rounded(_:weight:)** helper — 全 app 用 SF Pro Rounded
- **SpeakerButton** 加 pulse 動畫 + 長按速度選單
- **OnboardingView** Welcome step 加 Lexi
- **QuizResultView** 加 Lexi (pose 依分數)

### Changed
- 答錯不再用紅色 — 改 `AppColor.hug` 粉橘（no anxiety）
- 文案全面溫暖化：5 種時段問候、quiz 結果 3 種語氣、空狀態 Lexi 陪伴
- 詞庫詳情頁字體升大 (40pt → 56pt)

### Stats
- Files: 38 → 44 (+6 new)
- Localizable keys: 96 → 142 per locale (+46)

---

## [0.2.0] — 2026-05-20 · **Polished MVP**

> 改名、Onboarding、Tip Jar、schema v2。

### Added
- **App rename**：對外 `AgenticLex`、內部 `ClaudeCodeLex` 保留（避 Anthropic 商標）
- **Views/OnboardingView.swift** — 3 屏 first-launch（disclaimer / 雙語系選 / daily goal）
- **Trademark disclaimer** 從 Settings → 移到 Onboarding 第一屏顯眼處
- **terms.json schema v2** — 拆成 `terms.en.json` (主檔) + `terms.zh-TW.json` (翻譯)
  - 加 `isEnglishOnly` flag（10 個詞標記：MCP, API, hook, SDK, token, etc.）
  - 加 translation `status` (verified / ai / missing)
  - 加 `translator`, `updated`, `tagline` per-locale
- **Views/TipJarView.swift** + **Services/TipJarService.swift** — StoreKit 2 IAP × 3
- **Resources/Tips.storekit** — simulator 測試用 config
- **AppSettings** 加 `onboardingCompleted` / `tipJarLifetime` / `byokDisclosureShown`
- **i18n** 加 30 個新 keys（onboarding/tipjar/term.englishOnly）

### Changed
- **Quiz 預設方向** 從「英→母」改「母→英」（真正在學英文）
- ContentView gated on `onboardingCompleted` flag

### Removed
- Settings footer 的 trademark disclaimer（移到 onboarding）

### Stats
- Files: 29 → 38 (+9 new)
- Localizable keys: 66 → 96 per locale

---

## [0.1.0] — 2026-05-20 · **MVP Skeleton**

> 第一個能跑的版本：所有核心畫面與資料模型。

### Added
- iOS 16+ SwiftUI app skeleton
- **PRD.md / DESIGN.md / wireframe/index.html** 完整規格
- **App/ClaudeCodeLexApp.swift** + 4 個 tabs (Today / Browse / Quiz / Settings)
- **Models**: `Term`, `Translation`, `Category`, `UserProgress`, `LearnStatus`
- **Services**:
  - `TermStore` 載入 terms.json
  - `SpeechService` AVSpeechSynthesizer wrapper
  - `ProgressStore` SRS 簡化版 SM-2 + JSON persistence + streak
  - `AppSettings` UserDefaults preferences
- **Views**: `TodayView`, `BrowseView`, `TermDetailView`, `QuizView`, `SettingsView`
- **Components**: `TermCardMini`, `TermRow`, `SpeakerButton`, `CategoryChip`, `Block`, `AppColor`
- **Resources/terms.json** — 30 個 CC 詞庫種子資料（zh-TW 100% 翻譯）
- **Resources/*.lproj/Localizable.strings** — 6 語系（en/zh-Hant/ja/ko/es/pt）
- **README.md** — Xcode 整合 + 上架 SOP

### Stats
- 29 files
- 66 Localizable keys per locale
- 30 terms / 11 categories

---

## 命名 / 商標歷史

| 版本 | 對外名 | 為什麼 |
|---|---|---|
| v0.1 | ClaudeCodeLex | 第一版命名，直白但綁定 Anthropic 商標 |
| v0.2+ | AgenticLex | 跳脫商標，未來可涵蓋 Cursor / Cline |
| (內部) | ClaudeCodeLex | Xcode project / repo / file path 不動 |

---

## 統計總覽

```
v0.1: 29 files, 66 i18n keys
v0.2: 38 files, 96 i18n keys     (+9 files, +30 keys)
v0.3: 44 files, 142 i18n keys    (+6 files, +46 keys)
v0.4: 52 files, 178 i18n keys    (+8 files, +36 keys)
v0.5: +5 docs (HANDOFF/CLAUDE/CHANGELOG/ROADMAP/ARCHITECTURE + docs/INDEX.md)
```

---

## Maintainers

- 王宏盟 (gotman888@gmail.com) — Product + Design + Code review
- Claude (Cowork mode + Claude Code) — Implementation pair
