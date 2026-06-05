# CLAUDE.md — AgenticLex 專案記憶檔

> Claude Code 啟動時會自動讀這份。
> 這份的目的：讓你（Claude）一進來就 100% 進入狀況、不問廢話、直接做對的事。

---

## 一句話定位

**AgenticLex** = 給「會用 AI、但英文不是母語」的人學習 Claude Code 等 agentic coding 英文術語的 iOS app。

- 對外名：**AgenticLex**（App Store 顯示）
- 內部 code name：**ClaudeCodeLex**（Xcode project、檔案路徑）
- Owner：王宏盟（gotman888@gmail.com，台灣）
- 平台：iOS 16+ SwiftUI
- 商業：**永久免費**、Tip Jar 自願贊助、BYOK 用戶用自己 API key
- 開源：**github.com/gotman888/AgenticLex**（curated 公開快照，MIT code / CC-BY 內容；**非 auto-mirror**，app 改了要重 sync，見「常見任務 → 更新公開 repo」）

---

## 紅線（絕不可做）

1. **不要刪檔** — `terms.json` v1 stub 雖然 deprecated，但保留（用 `_DEPRECATED` 標）
2. **不要動 Anthropic 商標** — App 名是 `AgenticLex` 不是 `Claude Code Lex`
3. **不要把 API key 存 UserDefaults** — 全部走 `KeychainHelper`
4. **不要刪 Lexi 動畫** — 那是 product 的靈魂
5. **不要加後端** — 永遠保持 device-only，0 server
6. **不要加追蹤** — Privacy nutrition 全綠是賣點
7. **不要破壞 7 語系 keys 一致性** — 改 i18n 一定 7 個檔同步動

---

## 開工前必讀

1. `HANDOFF.md` — master plan，知道整體狀況
2. `docs/ARCHITECTURE.md` — codebase 拆解
3. `docs/ROADMAP.md` — 知道接下來要做什麼
4. 看 `CHANGELOG.md` 了解每版改過什麼

---

## 工作模式

王宏盟的 preferences（重要！）：
- **語言**：回應用繁中（zh-TW），技術名詞保留英文 + 中文 gloss
- **風格**：簡潔，conclusion-first + brief-why；不客套
- **計劃**：**plan-first → confirm → exec**。給建議結論先 + 短理由
- **不清楚**：列 pending 給 user 決定，不要 stealth-write
- **環境**：macOS、Xcode、Python+API key 偏好

不要：
- 過度解釋你做了什麼（user 看得到 git diff）
- 用客套話開場
- 一次改 10 個檔不分組

要：
- 改之前先列計畫
- 改完報摘要 + 影響範圍
- 用 TaskCreate / TaskUpdate 追進度

---

## 檔案地圖速查

```
ClaudeCodeLex/
├── App/
│   └── ClaudeCodeLexApp.swift      ← @main
├── Models/
│   ├── Term.swift                  ← 詞 / 翻譯 / 分類 schema v2
│   ├── UserProgress.swift          ← 學習狀態
│   ├── Achievement.swift           ← 10 個徽章定義
│   └── AIProvider.swift            ← BYOK 列舉
├── Services/
│   ├── AppSettings.swift           ← UserDefaults 偏好
│   ├── TermStore.swift             ← 載 terms.*.json
│   ├── ProgressStore.swift         ← 進度 + SRS
│   ├── SpeechService.swift         ← TTS 主入口（native + cloud）
│   ├── AIVoiceService.swift        ← OpenAI/ElevenLabs TTS HTTP
│   ├── AIVoicePlayer.swift         ← mp3 播放
│   ├── AIChatService.swift         ← Claude/GPT/Gemini chat
│   ├── TipJarService.swift         ← StoreKit 2 IAP
│   └── KeychainHelper.swift        ← API key 加密儲存
├── Views/
│   ├── ContentView.swift           ← Root (gated onboarding)
│   ├── OnboardingView.swift        ← 3 屏 first-launch
│   ├── TodayView.swift             ← Home Tab
│   ├── BrowseView.swift            ← Browse Tab
│   ├── QuizView.swift              ← Quiz Tab (含 ReviewSession)
│   ├── SettingsView.swift          ← Settings Tab
│   ├── TermDetailView.swift        ← 點詞進來的詳情頁
│   ├── ListenModeView.swift        ← 純聽連播
│   ├── AchievementsView.swift      ← 徽章網格
│   ├── TipJarView.swift            ← 3 級贊助
│   ├── AIBoostView.swift           ← BYOK Settings 子頁
│   ├── AskLexiView.swift           ← AI 對話 sheet
│   └── Components/
│       ├── LexiView.swift          ← 紫色 owl-bot 吉祥物（6 poses）
│       ├── CelebrationView.swift   ← 撒花動畫 overlay
│       ├── SpeakerButton.swift     ← 圓播放鈕（長按速度）
│       ├── TermCard.swift          ← TermCardMini + TermRow
│       ├── AppColor.swift          ← 設計 tokens
│       ├── Block.swift             ← Section block helper
│       └── CategoryChip.swift      ← Pill 標籤
└── Resources/
    ├── terms.en.json               ← 詞庫主檔（必加 bundle）
    ├── terms.zh-TW.json            ← 翻譯（必加）
    ├── terms.json                  ← v1 deprecated（不加 bundle）
    ├── Tips.storekit               ← simulator IAP 測試
    └── {en,zh-Hant,zh-Hans,ja,ko,es,pt}.lproj/Localizable.strings
```

---

## 設計準則

1. **聲音優先** — 每個畫面 1 鍵可發音
2. **英文錨點** — 英文是學習目標，**永遠不可隱藏**
3. **Lexi 陪伴** — 適當位置放 LexiView（onboarding / 空狀態 / 慶祝 / 答錯）
4. **不焦慮配色** — 答錯用 `AppColor.hug`（粉橘）**不用紅色**
5. **SF Pro Rounded** — 全 app 用 `.font(.rounded(size, weight:))`
6. **減法 UI** — 不放 user 用不到的功能

---

## 常見任務的標準步驟

### 加新詞

1. 編輯 `Resources/terms.en.json`（主檔 + metadata）
2. 編輯 `Resources/terms.zh-TW.json`（翻譯 + memoryHook + status: verified）
3. 跑驗證腳本：

```bash
python3 -c "
import json
main = json.load(open('ClaudeCodeLex/Resources/terms.en.json'))
zh = json.load(open('ClaudeCodeLex/Resources/terms.zh-TW.json'))
main_ids = {t['id'] for t in main['terms']}
zh_ids = set(zh['translations'].keys())
print('missing:', main_ids - zh_ids)
print('extra:', zh_ids - main_ids)
"
```

### 改 UI 字串

**必須改 7 個檔同步**：

```
Resources/en.lproj/Localizable.strings
Resources/zh-Hant.lproj/Localizable.strings
Resources/zh-Hans.lproj/Localizable.strings
Resources/ja.lproj/Localizable.strings
Resources/ko.lproj/Localizable.strings
Resources/es.lproj/Localizable.strings
Resources/pt.lproj/Localizable.strings
```

加新 key 後跑：

```bash
python3 -c "
import re, glob
keys = {}
for f in glob.glob('ClaudeCodeLex/Resources/*.lproj/Localizable.strings'):
    loc = f.split('/')[-2].replace('.lproj','')
    keys[loc] = set(re.findall(r'^\"([^\"]+)\"\s*=', open(f).read(), re.M))
base = keys['en']
for loc, ks in keys.items():
    if loc != 'en':
        m = base - ks; e = ks - base
        print(loc, 'missing:', len(m), 'extra:', len(e))
"
```

### 加新 AI provider

1. `Models/AIProvider.swift` 加 enum case + voices / keychainAccount
2. `Services/AIVoiceService.swift` 或 `AIChatService.swift` 加 HTTP method
3. `Services/SpeechService.swift` 的 `speakCloud` switch 加 case
4. UI 自動跑（AIBoostView 用 `ForEach allCases`）

### 改 Lexi 姿勢

`Views/Components/LexiView.swift` 已有 6 poses（wave/read/hug/cheer/wizard/sleepy）。要加新 pose：

1. 加 `LexiPose` enum case
2. 在 `arms` / `accessory` switch 加 case 與形狀
3. 用 `LexiView(pose: .yourNewPose)` 引用

### 加新 view

1. 在 `Views/` 或 `Views/Components/` 新增 .swift
2. 從某現有 view link 進去（NavigationLink / .sheet）
3. **不要動 ContentView TabView**（4 個 tab 已固定）

### 用 ScreenshotHarness 截圖驗收（免 ⌘R、給人看效果）

DEBUG-only harness 由 launch arg 把任一畫面當 root + 覆蓋設定。**靜態畫面可自動截**；
互動態（答錯 hug 色、空搜尋 Lexi、mail composer、評分提示）截不到，要真機 / ⌘R。

```bash
APP=build/sim/Build/Products/Debug-iphonesimulator/ClaudeCodeLex.app
xcrun simctl boot "iPhone 17 Pro"; xcrun simctl bootstatus "iPhone 17 Pro" -b
xcrun simctl install booted "$APP"
# screen: today/browse/detail/quiz/settings/conceptmap/learningpath/shadowread/sharecard
# 任何 -key value 進 UserDefaults argument domain → 可覆蓋 appearance.theme / learning.nativeLanguage
xcrun simctl launch booted com.gotman.agenticlex \
  -screenshotScreen detail -screenshotSet en -appearance.theme dark -learning.nativeLanguage ja
sleep 3; xcrun simctl io booted screenshot /tmp/shot.png
```
- en set → 母語西語（`status:ai`）→ 正好顯 AI badge；`detail` demo 詞 = `hook`。
- 先 build Debug（harness 在 `#if DEBUG`，Release 剔除）。UI chrome 語言＝模擬器系統語言，與設定無關。

### 更新公開 open-source repo

公開 repo（github.com/gotman888/AgenticLex）是這個私有倉的 **curated 快照**（非 auto-mirror）。app 改了要重 sync：

```bash
python3 tools/build_public_snapshot.py          # dry：copy+scrub+hard gate+比對遠端
python3 tools/build_public_snapshot.py --push   # 有差異才 force-push
```
排除清單（SOP / _apple-resolution / HANDOFF / 腳本自身 / public-overlay）+ scrub 規則
（Team ID / dev Apple ID / 金流 / 私案名 / 死連結）都在腳本內，含 **hard gate**（命中機敏 token 直接 abort）。
公開版的 LICENSE/README/CONTRIBUTING 放 `public-overlay/`。詳見 skill `repo-publish`。

---

## 驗收命令（每次大改後跑）

```bash
cd ~/Code/ClaudeCodeLex  # or your project path
# 1. Swift 編譯
xcodebuild -scheme ClaudeCodeLex \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build | tail -20

# 2. i18n 一致性（在 source folder 跑）
python3 -c "$(cat <<'PY'
import re, glob
keys = {}
for f in glob.glob('Resources/*.lproj/Localizable.strings'):
    loc = f.split('/')[-2].replace('.lproj','')
    keys[loc] = set(re.findall(r'^"([^"]+)"\s*=', open(f).read(), re.M))
base = keys.get('en', set())
print(f"en: {len(base)} keys")
for loc, ks in keys.items():
    if loc == 'en': continue
    diff = (base - ks) | (ks - base)
    print(f"{loc}: {'OK' if not diff else f'DIFF {len(diff)}'}")
PY
)"

# 3. 詞庫 schema
python3 -c "
import json
m = json.load(open('Resources/terms.en.json'))
z = json.load(open('Resources/terms.zh-TW.json'))
mi = {t['id'] for t in m['terms']}
zi = set(z['translations'].keys())
print(f'terms: {len(m[\"terms\"])}, zh missing: {len(mi-zi)}, zh extra: {len(zi-mi)}')
"
```

---

## 商業 / 法律

- App Store 描述需含商標聲明（見 `docs/APPSTORE_METADATA.md`）
- BYOK 部分有 Apple 審核補充說明在 ARCHITECTURE.md §7.3
- Privacy Policy / Support URL 要部署 GitHub Pages（v1.0 上架前必要）

---

## 你會犯的錯（提前提醒）

1. **不要忘記改 7 個語系**（i18n keys）
2. **不要在 UserDefaults 存 API key**（用 KeychainHelper）
3. **不要把 terms.json v1 stub 加進 Xcode bundle**
4. **改 schema 一定要驗證 zh-TW translations 對得上 main**
5. **加 cloud TTS 一定要有 native fallback**（user 體驗連續性）
6. **App Store 上架**：app 現為 **iPhone-only**（`project.yml` `TARGETED_DEVICE_FAMILY: "1"`，別改回 `"1,2"` 否則要補 iPad 截圖）。App Intent 的 `IntentDescription` 別用含 `"siri"` 的 localization key（會觸發 90626）。上架手續/踩雷/真實流程一律看 `docs/APPSTORE_CONNECT_SOP.md` 頂端「v1.0 上架實戰總結」。

---

## 風格參考

讀過去的 commit / 文件學語氣：
- `docs/PRD.md` 是規格寫作 reference
- `docs/FRIENDLY_LEARNING.md` 是哲學論述 reference
- `docs/AI_BYOK_DESIGN.md` 是技術設計 reference

統一風格：conclusion-first、短理由、表格多、emoji 適度（不超過 1 個/段落）。

---

End of CLAUDE.md
