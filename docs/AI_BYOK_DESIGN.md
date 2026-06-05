# AgenticLex — AI BYOK (Bring Your Own Key) 設計

> v0.4 / 2026-05-20 / 你想到的關鍵 insight：user 是 AI native 族群

---

## 0. Insight 重申

「AgenticLex 的使用者，都是對 AI 有興趣的使用者」這句話**改變了 product 定位**：

| v0.3 定位 | v0.4 定位 |
|---|---|
| 一個離線的 vocab learning app | 一個**為 AI native 設計**的學習平台 |
| 所有用戶看到一樣的內容 | 用戶可用**自己的 API key 升級體驗** |
| 競品：Duolingo、Anki | 競品：**沒人做這個 niche** |

這也意味著：**Free 體驗要扎實，但 BYOK 讓重度 user 飛起來**。

---

## 1. 七個可 AI 升級的維度

| 維度 | 預設 (Free) | BYOK 升級 | Provider |
|---|---|---|---|
| 1. **語音 Voice** | iOS AVSpeechSynthesizer | 業界最強自然 TTS | ElevenLabs / OpenAI TTS / Cartesia |
| 2. **問 Lexi 對話** | (無，預設沒有對話) | 與 AI 對話釐清概念 | Claude / GPT / Gemini |
| 3. **例句生成** | 靜態 example 1 句 | 即時生新例句、領域化 | Claude / GPT |
| 4. **個人化解釋** | 通用定義 | 「用我的程度/領域解釋」 | Claude / GPT |
| 5. **詞庫擴充** | 30 個固定 | AI 從你的領域加詞 | Claude / GPT |
| 6. **跟讀比對** | iOS Speech framework | OpenAI Whisper 更精準 | OpenAI |
| 7. **學習推薦** | SRS 基本演算 | AI 分析你弱點推薦 | Claude / GPT |

### 1.1 為什麼語音 BYOK 是 P0

**痛點**：AVSpeechSynthesizer 對 "PreToolUse"、"SubagentStop"、"MCP" 這類複合詞 / 縮寫**唸得很機械**。
而 user 你說「聲力學習能力強」— 發音品質直接影響學習效果。

**ElevenLabs `eleven_turbo_v2.5`**：
- 自然度 9/10
- streaming 延遲 < 500ms
- ~$0.0003 per character → 一個詞 10 字 ≈ $0.003 ≈ NT$0.1
- **一個月 1000 次播放 ≈ $3 USD**（合理）

**OpenAI `tts-1-hd`**：
- 自然度 8/10
- 6 種 voice (alloy / echo / fable / onyx / nova / shimmer)
- $0.030 / 1K chars → 一個詞 ≈ $0.0003 ≈ NT$0.01
- **一個月 1000 次播放 ≈ $0.30 USD**（極便宜）

**OpenAI TTS 是 BYOK 默認最佳選擇**（價格 1/10 + 品質夠）。
**ElevenLabs 是給最在乎品質的 user**。

### 1.2 為什麼 Ask Lexi 是 P1

target user 都用 Claude Code，**他們本能想「問 Claude」**。在 app 內按一下「問 Lexi」彈出對話視窗，用 user 自己的 Anthropic key 直接打 Claude API — 這是「**他們已經在 Claude Code 的 mental model 的延伸**」。

例句：
- 「Hook 跟 Skill 差在哪？」 → Claude 用 zh-TW 回
- 「給我 5 個 sub-agent 在電商應用的真實例子」 → Claude 生
- 「我剛學的 SubagentStop，幫我寫一個範例 hook script」 → Claude 寫 code

這比看靜態 definition 強 10 倍。

---

## 2. BYOK Settings UX 設計

### 2.1 入口

```
Settings
├── (existing sections)
├── Support development (Tip Jar)
├── ✨ AI Boost ← NEW
└── About
```

「AI Boost」加✨ icon 凸顯。tap 進子頁。

### 2.2 AIBoostView 結構

```
AI Boost
─────────────────────────────────────
🦉 Lexi can do more with your own
AI API keys. Free forever — only
charges go to your own provider.
─────────────────────────────────────

🔊 BETTER VOICES
┌─────────────────────────────────┐
│ Current: iOS built-in           │
│ Tap to upgrade to a cloud voice │
└─────────────────────────────────┘

┌─ OpenAI TTS ──────────────── ◯ ─┐
│ API Key  •••••••••••••• 💾      │
│ Voice    [ nova       ▾ ]       │
│ Test     ▶ "Slash Command"      │
│ Cost     ~$0.0003 per word      │
│ → openai.com/api/keys           │
└─────────────────────────────────┘

┌─ ElevenLabs ──────────────── ◯ ─┐
│ API Key  •••••••••••••• 💾      │
│ Voice    [ Rachel     ▾ ]       │
│ Test     ▶ "Slash Command"      │
│ Cost     ~$0.003 per word       │
│ → elevenlabs.io/app/account     │
└─────────────────────────────────┘

💬 ASK LEXI (chat)
─────────────────────────────────────
Have a conversation about any term
with your favorite AI.

┌─ Anthropic Claude ─────────  ◯ ─┐
│ API Key  •••••••••••••• 💾      │
│ Model    [ Sonnet 4.6 ▾ ]       │
│ → console.anthropic.com         │
└─────────────────────────────────┘

┌─ OpenAI GPT ──────────────── ◯ ─┐
│ ...                              │
└─────────────────────────────────┘

⚠️ Your keys are stored locally
in iOS Keychain. Requests go
directly to the provider — never
through our servers.
```

### 2.3 互動細節

- 每張 provider card 一個 toggle：開了才會用
- 同類型（voice / chat）只能擇一啟用（單選 radio behavior）
- 「Test」按鈕用當前設定播一句範例 → 用戶馬上聽到差異
- key 輸入框遮罩，已存的顯示前 4 字 + `••••••••`
- 「→ provider.com/keys」是 nominative link，不是 affiliate / sales

### 2.4 提示與警告

第一次開啟 BYOK toggle 時跳 dialog：
> 「你的 API key 會存在 iOS 鑰匙圈，只用來呼叫該 provider。
> AgenticLex 不會把 key 傳到任何地方。
> 你的請求**直接**送往 provider 伺服器 — 請參考他們的隱私政策。」

---

## 3. 技術架構

### 3.1 新檔案

```
Models/
└── AIProvider.swift          // 列舉：openai, elevenlabs, claude, gemini

Services/
├── KeychainHelper.swift      // Generic password keychain wrapper
├── AIVoiceService.swift      // 統一 TTS 介面，可切換 native/cloud
├── AIChatService.swift       // Ask Lexi 對話
└── AIVoicePlayer.swift       // 播 cloud TTS 回來的 mp3/pcm

Views/
├── AIBoostView.swift         // Settings 子頁
└── AskLexiView.swift         // 對話泡泡 sheet
```

### 3.2 Provider 列舉

```swift
enum AIVoiceProvider: String, CaseIterable {
    case native        // AVSpeechSynthesizer (default)
    case openai        // tts-1-hd
    case elevenlabs    // eleven_turbo_v2_5

    var displayName: String { ... }
    var keychainKey: String { ... }
    var voices: [String] { ... }
    var costHintKey: String { ... }     // i18n key for "~$X per word"
}

enum AIChatProvider: String, CaseIterable {
    case claude        // anthropic
    case openai
    case gemini

    var apiEndpoint: URL { ... }
    var keychainKey: String { ... }
}
```

### 3.3 Keychain 策略

不要存 UserDefaults — 不安全。用 `kSecClassGenericPassword`：

```swift
enum KeychainHelper {
    static func save(_ key: String, account: String) -> Bool { ... }
    static func read(account: String) -> String? { ... }
    static func delete(account: String) -> Bool { ... }
}
```

account naming：`com.gotman.agenticlex.apikey.openai`, `.elevenlabs`, `.claude`, `.gemini`

### 3.4 SpeechService 整合

```swift
final class SpeechService {
    @Published var voiceProvider: AIVoiceProvider = .native

    func speak(_ text: String, language: String = "en-US") {
        switch voiceProvider {
        case .native:
            speakNative(text, language: language)
        case .openai:
            Task { await speakOpenAI(text) }
        case .elevenlabs:
            Task { await speakElevenLabs(text) }
        }
    }

    // Cloud TTS fallback：如果 API 失敗，自動 fallback 到 native
    private func speakOpenAI(_ text: String) async {
        do {
            let audio = try await AIVoiceService.openAI(text: text, ...)
            AIVoicePlayer.shared.play(audio)
        } catch {
            // toast: "Cloud voice failed, using built-in"
            speakNative(text)
        }
    }
}
```

### 3.5 API 簽名（精簡版）

**OpenAI TTS**
```
POST https://api.openai.com/v1/audio/speech
Authorization: Bearer {key}
Body: {
  "model": "tts-1-hd",
  "input": "Slash Command",
  "voice": "nova",
  "response_format": "mp3"
}
→ binary mp3 stream
```

**ElevenLabs**
```
POST https://api.elevenlabs.io/v1/text-to-speech/{voice_id}/stream
xi-api-key: {key}
Body: {
  "text": "Slash Command",
  "model_id": "eleven_turbo_v2_5",
  "voice_settings": { "stability": 0.5, "similarity_boost": 0.75 }
}
→ binary mp3 stream
```

**Claude (Ask Lexi)**
```
POST https://api.anthropic.com/v1/messages
x-api-key: {key}
anthropic-version: 2023-06-01
Body: {
  "model": "claude-sonnet-4-6",
  "max_tokens": 1024,
  "system": "You are Lexi, a friendly tutor inside AgenticLex...",
  "messages": [{"role": "user", "content": "Hook 跟 Skill 差在哪？"}]
}
→ Claude response
```

### 3.6 Ask Lexi 對話設計

進入點：TermDetailView 加一個 button「💬 Ask Lexi about this」（**僅當 chat key 已設**）。

對話頁是 sheet：
- 頂部：詞 + Lexi 大頭照
- 中間：對話 bubbles（user 右、Lexi 左 + Lexi avatar）
- 底部：input + 「Quick prompts」chips
  - 「Explain like I'm 5」
  - 「Give me 3 more examples」
  - 「Show me code」
  - 「Compare with Skill」

**初始 system prompt**（給 LLM）：
```
You are Lexi, a friendly purple owl-bot tutor inside AgenticLex,
an iOS app teaching Claude Code terminology to non-native English speakers.

Context:
- The user is learning the term: {term.english}
- Their native language: {locale}
- Difficulty level: {term.difficulty}

Rules:
- Always respond in {locale} unless they ask for English
- Keep responses under 150 words unless code is requested
- Use real Claude Code examples
- Be warm and encouraging
- If asked something off-topic, gently redirect
```

對話歷史本地保留（per term）— 隔天回來看得到。

---

## 4. 商業模式更新

### 4.1 三層 user

| 層級 | 體驗 | 我們收入 |
|---|---|---|
| Casual | iOS built-in 全功能 | $0 (Tip Jar) |
| Power (BYOK) | Cloud voice + Ask Lexi | $0 (Tip Jar，用戶付給 provider) |
| Future Pro | 我們代買 token 包月 | $4.99/mo (v2.0+) |

v1.0：只做前兩層。Tip Jar 已有。

### 4.2 為何 BYOK 不收費比較好

1. **信任** — 用自己 key 等於透明
2. **無金流** — 我們不負責結算
3. **零客訴** — 用量問題找 OpenAI / Anthropic，不是我們
4. **Apple 審核更穩** — 沒有 IAP 機制等於沒風險

---

## 5. Apple 審核重點

### 5.1 Guideline 3.1.3(b) Multiplatform Services

允許這種「用戶在外面買服務、拿來 app 內用」的設計。**但**：

✅ 可做
- 「貼上你的 ElevenLabs API key」
- 「Get your key at elevenlabs.io」純文字連結
- 預估成本「~$0.003 per word」純資訊

❌ 不可做
- 「Buy ElevenLabs subscription」call-to-action
- App 內顯示 provider 的價格表 / 包月選項
- 任何 affiliate / referral

我們的設計**符合**。

### 5.2 隱私 disclosure（必要）

App Privacy nutrition label 要加：
- Data Linked to You: **NO** (我們不收資料)
- Data Used to Track You: **NO**
- **But add a note**: "If you enable BYOK features, your queries are sent to third-party AI providers per their own privacy policies."

在 Settings 加 disclosure：
- 啟用任何 BYOK toggle 時跳一次性 dialog
- AIBoostView 底部固定 disclosure 段落

### 5.3 競品案例

- **ChatGPT for iOS** 早期就是 BYOK 模式
- **Voicedream Reader** — 老牌 reader，支援多個 cloud TTS BYOK
- **Petey** (Apple Watch ChatGPT) — BYOK
- **Pal Chat** — BYOK + 多 provider

全部審核過。我們安全。

---

## 6. 階段性 release

| 版本 | 預計 | BYOK 範圍 |
|---|---|---|
| v0.4 | T+10 | 架構：Keychain + AIProvider model + Settings UI |
| v0.5 | T+15 | OpenAI TTS 整合（最便宜，先驗證流程） |
| v0.6 | T+20 | ElevenLabs TTS 整合 |
| v0.7 | T+25 | Ask Lexi with Claude |
| v0.8 | T+30 | Ask Lexi with OpenAI / Gemini |
| v1.0 | T+40 | 全部整合上架 |

本次 session 做 **v0.4 完整 + v0.5 OpenAI TTS + v0.7 Ask Lexi (Claude)** 的程式碼骨架。
ElevenLabs 與 Gemini 留 stub，按同樣 pattern 補。

---

## 7. 風險與緩解

| 風險 | 緩解 |
|---|---|
| 用戶 key 外洩 | Keychain 存、HTTPS 直連 provider、無自家後端 |
| Cloud TTS 失敗造成體驗中斷 | 自動 fallback native，toast 提醒 |
| 用戶不小心爆量花大錢 | UI 顯示 cost hint、Settings 加「Daily cap」未來功能 |
| 不同 provider API 變動 | Service 層抽象，改一處不影響 UI |
| Apple 質疑 BYOK | 隱私 disclosure 完整、無金流引導 |

---

## 8. 給王宏盟的話

這個 insight 是這次最關鍵的轉變。AgenticLex 從「給 user 學的 dict」變成「給 AI native 的可程式化學習平台」。

實作上：
- v0.4 我把 KeychainHelper + AIProvider + Settings UI 做扎實，未來加任何 provider 都是 1 個檔案
- OpenAI TTS 優先做完整（最便宜、最易驗證）
- Ask Lexi with Claude 對你的 user 最有共鳴（他們本來就用 Claude Code）

**這比加更多 features 都重要**。

---

End of AI_BYOK_DESIGN.md
