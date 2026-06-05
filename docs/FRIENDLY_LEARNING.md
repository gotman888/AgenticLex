# AgenticLex — Friendly Learning Design

> v0.3 / 2026-05-20
> 對「聲音 / 親人和善 / 樂在學習 / 學好 Claude Code」四項主題的深度設計

---

## 0. 設計哲學轉變

**v0.2 之前**：app 是「字典 + 測驗 + 進度」工具
**v0.3 之後**：app 是「陪伴你學的小老師 Lexi」

差別在於：**情感連結**。一個工具好不好用 → 一個朋友想不想再見。

---

## 1. 🔊 聲音 (Audio) — 從「能用」到「聽不夠」

### 1.1 當前 v0.2 audio 的 6 個盲點

1. **單次播放思維** — 點 🔊 唸一次。但聽力學習實證：要 5-10 次才能形成肌肉記憶
2. **無速度檔位** — 只有單一語速 0.45。慢速練聽辨、正常速練流暢、快速練腦補
3. **無 IPA 對齊** — 看到 `/slæʃ kəˈmænd/` 但不知道哪個音對哪個字
4. **無連續模式** — 通勤時想閉眼純聽 5 個詞，不可能（每個都要按）
5. **無背景播放** — App 切換到背景就斷音
6. **無「跟讀」結構** — 聽 → 等 → 跟著唸 → 對比，這個 loop 沒實作

### 1.2 v0.3 audio 五大新模組

#### A. 三檔語速 (Speed Stepper)

```
🐢 0.35 (Slow)     — 練聽辨，每個音節都聽清楚
🚶 0.45 (Normal)   — 預設，正常對話速度
🏃 0.55 (Fast)     — 練流暢，模擬母語人說話
```

UI: SpeakerButton 長按 → 跳出 segmented control 三選一。一般點擊用當前設定。

#### B. Repeat × N

對著一個詞，播 1 / 3 / 5 / ∞ 次自動重複，間隔 0.8 秒。

實作：`AVSpeechSynthesizer` 的 delegate `didFinish` 回呼裡 enqueue 下一次 utterance，直到計數歸零。

UI: SpeakerButton 旁加 🔁 icon，點開選 1/3/5/∞。

#### C. Listen Mode (純聽連播)

**情境**：你在開車 / 走路 / 通勤，不能盯螢幕。打開 Listen Mode 後：
- 自動連續唸 N 個詞（5 / 10 / 全部 due review）
- 每個詞順序：英文唸 → 0.5s 停 → 中文唸（母語）→ 1s 停 → 下一詞
- 鎖屏 + 背景時繼續播放
- iOS 鎖屏顯示「正在播放: PreToolUse」+ Play/Pause/Next 控制
- 結束播：「今天聽了 X 個詞 ✨」

**這是真正的「聽力學習」**，是市面上 vocab app 普遍沒做好的。

實作要點：
- `AVAudioSession.Category.playback`（已設）
- `MPNowPlayingInfoCenter` 顯示鎖屏資訊
- `MPRemoteCommandCenter` 接 Play/Pause/Next
- Info.plist 加 `UIBackgroundModes` → `audio`

#### D. IPA 視覺對齊 (Karaoke-style highlight)

`/slæʃ kəˈmænd/` 在唸到對應音節時 highlight。

實作簡化版（v1.0）：
- 把 IPA 拆音節：`/slæʃ/` + `/kəˈmænd/`
- 用 `AVSpeechSynthesizer` delegate 的 `willSpeakRangeOfSpeechString` 抓 character range
- 比例對齊到 IPA 音節
- 對應音節變色 + 微縮放

實作複雜版（v1.5+）：
- 用 Speech framework 抓 phoneme timing
- 真正精準同步

v1.0 用簡化版即可，已經夠 wow。

#### E. 跟讀模式 (Shadow Read)

**情境**：點「跟讀」→ Lexi 唸 → 「換你」提示 → 用戶按住麥克風唸 → Speech framework 比對 → 給 ✓/✗ + 鼓勵。

技術：
- `SFSpeechRecognizer` (locale: en-US)
- 比對 `SFTranscription.formattedString` 與目標 term
- 用 Levenshtein distance 容錯（差 1 字以內算對）
- 不上傳雲端（隱私）

v1.0 範圍：選做（要 Microphone Permission）
v1.1 範圍：必做

---

## 2. 😊 親人和善 (Friendly UI) — 從「工具」到「朋友」

### 2.1 v0.2 介面的 5 個冷感點

1. **沒有「人」陪你** — 純 SF Symbols，沒有角色
2. **文案太「機器」** — `今天的 5 個詞` 像 to-do list 而非邀請
3. **答錯只標紅** — 沒有「沒關係」的同理心
4. **配色偏冷** — 紫色 + 灰白，沒有家的暖意
5. **字體偏正式** — SF Pro Display 太「商務」

### 2.2 v0.3 Friendly 五大改造

#### A. Lexi — 紫色 Owl Bot 吉祥物

**形象**：紫色機器貓頭鷹 (owl-bot)，圓滾滾、眼睛大、會眨眼。
- 貓頭鷹 = 智慧 + 學習傳統意象（Duolingo 也是 owl）
- 機器人 = AI / agentic coding 主題感
- 圓滾滾 = 親人、無威脅感
- 紫色 = 維持 Claude / brand 一致

**出現時機**：
- Onboarding 第一屏: Lexi 揮手「Hi, I'm Lexi! Let's learn together.」
- 空狀態（沒詞學）: Lexi 抱本書「Yay! All done for today 🎉」
- 答錯時: Lexi 抱抱「No worries, try again!」
- 達成里程碑: Lexi 撒花「You learned 10 words! 🎊」
- Settings: Lexi 拿扳手「Tune me up」
- Random Word 按鈕: Lexi 戴帽子 magician

**實作**：SVG 內嵌 SwiftUI（不用 PNG，scale 自由、theme aware）。3-5 個姿勢（wave / read / hug / cheer / wizard）。

#### B. 文案全面溫暖化

對比範例（zh-TW）：

| 場景 | v0.2 (冷) | v0.3 (暖) |
|---|---|---|
| Greeting | `今日` | `早安，今天來認識新朋友吧 👋` |
| Today picks | `今天的 5 個詞` | `我準備了 5 個詞要介紹給你 ☕` |
| 答對 | `+1` | `沒錯！就是這個 ✨` |
| 答錯 | `❌` | `差一點點，再看一眼` |
| Quiz 完成 | `5/5` | `完美！今天的 Lexi 很驕傲 🎉` |
| 空 mastered | `No mastered yet` | `第一個學會的詞會永遠記得這一刻 🌱` |
| Streak 1 | `🔥 1` | `🔥 1 天 — 開始了！` |
| Streak 7 | `🔥 7` | `🔥 一週了 — Lexi 為你拍手 👏` |
| Streak 30 | `🔥 30` | `🔥 一個月 — 你比 90% 的人更堅持 ⭐` |
| Error state | `Failed to load` | `咦？Lexi 卡住了，再試一次？` |

#### C. SF Pro Rounded 全面換字體

- `Text(...).font(.system(...))` → `Text(...).font(.system(..., design: .rounded))`
- 圓潤字體更友善、像繪本，符合學習氛圍
- Apple HIG 也建議 child-friendly / casual app 用 rounded

#### D. Warm Palette 微調

新增暖色 tokens：

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `WarmBg` | `#FFFBF5` | `#1A1812` | 主背景（米黃） |
| `WarmCard` | `#FFF6E8` | `#26221A` | 卡片背景 |
| `LexiPurple` | `#8B6FFF` | `#A48BFF` | Lexi 主色 |
| `Cheer` | `#FFB84D` | `#FFC772` | 慶祝色 |
| `Hug` | `#FFA8A8` | `#FF9090` | 答錯安慰色（不是紅！） |

關鍵：**答錯不用紅色**。紅 = 危險、焦慮。改用粉橘 `#FFA8A8` = 溫和、可再試。

#### E. 微互動 (Micro-interactions)

- Tap：spring animation (`.interactiveSpring`)
- 答對：✓ + scale bounce + haptic `.success`
- 達成 streak：confetti + Lexi 撒花
- 載入：Lexi 在 spinner 中心轉動（不要冷冰冰 ProgressView）

---

## 3. 🎉 樂在學習 (Joy / Engagement)

### 3.1 v0.2 缺的 6 個「為什麼想打開」

1. **打開沒驚喜** — 每天同樣的 Today 畫面
2. **學完沒慶祝** — 學會詞跟「next」一樣，沒儀式感
3. **沒徽章** — 達成里程碑沒視覺獎勵
4. **不能分享** — 學會酷詞想 IG 炫耀無從產圖
5. **無探索按鈕** — 想看就看，必須走 Browse / Quiz
6. **沒同伴感** — 一個人在學，孤獨

### 3.2 v0.3 Engagement 七大新元素

#### A. Word of the Day (WOTD)

首頁最頂、永遠有一個今日特選詞。每天 0:00 換。
- 大字、Lexi 站旁邊
- 「Today's Star Word」標籤
- 點進去看完整 detail
- 學會 +1 special XP

挑選邏輯：簡單版用日期 hash（同天所有人看到同一個）；進階版用「user 未學過 + difficulty 適中」。

#### B. Random Word button (Lexi's Pick)

主畫面浮動按鈕 🎲，按下隨機跳一個未學過的詞。  
Lexi 變成 magician 拿魔法棒。  
**為什麼有用**：適合零碎 10 秒，不想規畫，純探索。

#### C. Achievement Badges (徽章系統)

10 個初始徽章：

| 徽章 | 條件 | Lexi 姿勢 |
|---|---|---|
| 🌱 First Word | mastered 1 詞 | 抱種子 |
| 📚 Bookworm | mastered 10 詞 | 看書 |
| 🎓 Scholar | mastered 30 詞 | 戴學士帽 |
| 🌟 Master | mastered 全部詞 | 王冠 |
| 🔥 Spark | streak 3 天 | 火花 |
| 🔥🔥 Flame | streak 7 天 | 火焰 |
| 🔥🔥🔥 Blaze | streak 30 天 | 大火 |
| 🦉 Night Owl | 半夜 0-3 點學習 | 戴睡帽 |
| 🌅 Early Bird | 早上 5-7 點學習 | 戴太陽眼鏡 |
| ☕ Coffee Helper | 第一次 tip | 拿咖啡 |

Settings 加 Achievements 入口。Unlock 時跳 modal + confetti。

#### D. Share Card

學會某詞後，可生成一張漂亮 image card：
- 紫色漸層背景 + 詞 + 翻譯 + Lexi
- "I just learned PreToolUse on AgenticLex 🎉"
- 一鍵分享 IG / X / LINE

實作：SwiftUI view → render to UIImage → `ShareSheet`

#### E. Concept Map (關係圖)

新 tab 或 Browse 子畫面：視覺化 Hook / Skill / Plugin / MCP / Agent 之間的關係。
- 用 SwiftUI Path / Canvas 畫
- 點節點跳該詞 detail
- 對視覺型學習者特別有用

#### F. Daily Streak Notification

iOS Local Notification（不需 server）：
- 21:00 提醒：「Lexi 在等你 — 還沒學完今天的詞 🦉」
- 隔天 09:00：「新的一天，新的詞！」
- 用戶可關

要求 `UNUserNotificationCenter` 權限，但是 nice-to-have。

#### G. Celebration Moments

學完一個詞 / mastered / streak +1 / 達成徽章 → 短動畫：
- ✓ 大勾勾 fade in + bounce
- 1-2 秒 confetti
- Lexi 配合姿勢
- haptic `.success`

不打斷學習，1.5 秒結束。

---

## 4. 🧠 學好 Claude Code (Learning Effectiveness)

### 4.1 terms.json schema v3 — 加情境欄位

```json
{
  "id": "hook",
  "english": "Hook",
  "isEnglishOnly": true,
  ...
  "translations": {
    "zh-TW": {
      "term": "鉤子",
      "definition": "...",
      "example": "...",
      "memoryHook": "...",
      "realUse": "用戶常見對話：『我想在每次 Edit 後自動 commit。』Claude: 『好的，我用 PostToolUse hook 設定。』",
      "commonConfusion": "Hook 和 Skill 不同：Hook 是『時機』，Skill 是『能力』。Hook 在特定事件觸發，Skill 在用戶請求觸發。",
      "verbForm": "I add a hook / I hook into / I write a PostToolUse hook"
    }
  }
}
```

新 3 個欄位：
- `realUse` — 真實對話片段（讓 user 看到真人怎麼說）
- `commonConfusion` — 常見混淆（pre-empt 誤解）
- `verbForm` — 動詞用法（學了能造句）

### 4.2 學習階梯 (Learning Path)

當前所有詞並列。應該有：
- **Level 1 (新手)**：Slash Command, Tool, Skill, Plugin, Permission, Session — 12 個基本詞
- **Level 2 (中階)**：Hook, MCP, Agent SDK, Context Window, Token — 進階概念
- **Level 3 (高手)**：SubagentStop, Compaction, Worktree, Live Artifact — 深度功能

UI: Browse 加「Level Path」tab，視覺像關卡進度條。

### 4.3 對比學習頁面 (Compare)

「Hook vs Skill」、「MCP vs Plugin」、「Tool vs Subagent」… 容易混淆的詞對。  
單一畫面並列兩個 Term，把差異標出來。

---

## 5. 實作優先級

對應這次要改：

| Pri | 項目 | 對應主題 |
|---|---|---|
| **P0** | Lexi mascot (SVG, 5 姿勢) | 親人 |
| **P0** | Warm palette + SF Pro Rounded | 親人 |
| **P0** | Audio speed 3 檔 + repeat | 聲音 |
| **P0** | Listen Mode (連播 + 背景) | 聲音 |
| **P0** | Friendly 文案重寫 (zh-TW + en) | 親人 |
| **P0** | Celebration (✓ bounce + confetti) | 樂在 |
| **P0** | Word of the Day | 樂在 |
| **P1** | Achievement badges (10 個) | 樂在 |
| **P1** | IPA 視覺對齊 | 聲音 |
| **P1** | Random Word button | 樂在 |
| **P1** | terms.json v3 加 realUse/commonConfusion | 學好 CC |
| **P2** | Share Card | 樂在 |
| **P2** | Concept Map | 學好 CC |
| **P2** | Shadow Read (跟讀+語音辨識) | 聲音 |
| **P2** | Daily streak notification | 樂在 |
| **P2** | Learning Path levels | 學好 CC |

---

## 6. 給王宏盟的話

技術上 v0.2 已經能 ship。但你問的「樂在學習」是 product 層面的，不是 spec 層面的。

最大的 leverage 點：
1. **Lexi** — 一個吉祥物可以讓「冷工具」變「朋友」，這是 product 0→1 差距
2. **Listen Mode** — 你說你是「聲力學習能力強」的人，這個直接對應你的學習偏好
3. **Celebration** — 學習產品 retention 的核心，Duolingo 整個架構就是 celebration loop

剩下的 P2 慢慢加，每加一個就是給用戶一個「再回來」的理由。

---

End of FRIENDLY_LEARNING.md
