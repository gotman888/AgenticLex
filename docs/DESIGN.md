# ClaudeCodeLex — UI/UX Design Spec

> v0.1 / 2026-05-20 / 對應 PRD v0.1
> 目標：給 Claude Code 在 Xcode 寫 SwiftUI 時的視覺與互動規範

---

## 1. 設計原則 (Principles)

1. **聲音優先 (Audio-first)** — 每個畫面 1 鍵可發音
2. **減法 (Reductive)** — 不放使用者用不到的功能，留白多
3. **大字 (Type-led)** — 英文詞顯示用 SF Pro Display 48-72pt
4. **不焦慮 (Calm)** — 沒有紅色錯誤 / 連勝壓力，streak 用溫和橙色
5. **可單手操作** — 主要互動在底部 1/3 螢幕

---

## 2. 視覺 Token (Design Tokens)

### Color (Light / Dark 雙模)

| Token | Light | Dark | 用途 |
|---|---|---|---|
| `BrandPrimary` | `#7C5BFF` | `#A48BFF` | 主色 (Claude 紫) |
| `BrandSecondary` | `#FF9A3C` | `#FFB266` | streak/重點 (溫和橙) |
| `BgPrimary` | `#FFFFFF` | `#0E0E12` | 背景 |
| `BgCard` | `#F6F4FF` | `#1B1B24` | 卡片背景 |
| `TextPrimary` | `#0E0E12` | `#F5F5FA` | 主文字 |
| `TextSecondary` | `#6B6B7A` | `#9B9BAC` | 次文字 |
| `Success` | `#34C759` | `#30D158` | mastered 標記 |
| `Divider` | `#E5E5EA` | `#2C2C35` | 分隔線 |

### Typography (SF Pro)

| Style | Size | Weight | Line | 用途 |
|---|---|---|---|---|
| `display-xl` | 56 | Bold | 1.05 | Term Detail 大標 |
| `display-l` | 40 | Bold | 1.1 | Quiz 題目 |
| `title-l` | 28 | Semibold | 1.2 | 畫面標題 |
| `title-m` | 20 | Semibold | 1.25 | 卡片標題 |
| `body-l` | 17 | Regular | 1.4 | 內文 |
| `body-m` | 15 | Regular | 1.4 | 次內文 |
| `caption` | 13 | Medium | 1.3 | 標籤、metadata |

Dynamic Type：全部用 `.font(.system(...))` + Style，支援使用者放大。

### Spacing (8pt grid)

`4 / 8 / 12 / 16 / 24 / 32 / 48`

### Radius

| Token | px | 用途 |
|---|---|---|
| `r-sm` | 8 | chip / tag |
| `r-md` | 16 | card |
| `r-lg` | 24 | sheet |
| `r-pill` | 999 | button pill |

### Elevation
- 卡片：no shadow，靠 BgCard 區隔（Dark mode 友善）
- 浮起按鈕：subtle `shadow(radius: 8, y: 4, opacity: 0.08)`

---

## 3. 資訊架構 (IA)

```
TabView (4 tabs)
├─ Today (Home)
├─ Browse
├─ Quiz
└─ Settings

Modal (presented over any tab):
└─ TermDetailView (push or sheet)
```

---

## 4. 主要畫面 (Screen-by-Screen)

### 4.1 Today (Home Tab) 🏠

**結構（由上而下）**
1. Top bar
   - 左：「ClaudeCodeLex」logo wordmark
   - 右：🔥 + streak 數字 (e.g. `🔥 7`)
2. Greeting block
   - `morning/afternoon/evening` + 母語問候
   - 副標：`今天的 5 個詞 / Today's 5 words`
3. **Today's Picks** — 水平捲動 5 張卡片
   - 每張卡：分類 chip / 英文大字 / 母語小字 / 🔊 icon
4. Quick action
   - 「開始今日學習」大按鈕 (BrandPrimary, 32pt 文字)
5. Recently learned
   - 列出最近 mastered 的 3 個詞 (小卡)

**互動**
- 點卡片 → push TermDetailView
- 點「開始」→ enter ReviewSessionView (依序播放 5 張)

---

### 4.2 Browse Tab 📚

**結構**
1. Top: SearchBar `🔍 搜尋 / Search terms…`
2. Category chips (水平捲動): All / CLI / Hooks / MCP / Sub-agents / Plugins / Skills / Artifacts / Tools / Context / Prompting / Misc
3. List of terms (LazyVStack)
   - 每列：左 status dot (灰=new, 紫=learning, 橙=reviewing, 綠=mastered；用 brand tokens 非系統色) / 英文 / 母語 / 🔊

**互動**
- 點列 → TermDetailView
- 長按列 → context menu (Favorite / Mark mastered / Reset)

---

### 4.3 Term Detail View 🔍

**結構（上下排列，可垂直捲動）**
1. Hero block (BgCard, 全寬, 圓角 24)
   - 分類 chip (small)
   - 英文大字 `display-xl` (e.g. `Slash Commands`)
   - IPA `/slæʃ kəˈmændz/` (caption, TextSecondary)
   - 🔊 大圓按鈕 (72×72, BrandPrimary fill)
2. Translation block
   - 母語標題 (title-l): 「斜線指令」
   - Definition (body-l)
3. Example block
   - 標題: 「實際用法 / In context」
   - 程式碼風格背景 + 例句（混 EN/L1）
4. Memory hook block (optional)
   - 💡 圖示 + 記憶法文字
5. Related terms
   - 「相關詞 / Related」+ 水平 chip 列
6. Bottom action bar (sticky)
   - ⭐ Favorite / ✅ Mark mastered / 🔄 Reset

**互動**
- 點 🔊 → AVSpeechSynthesizer 唸英文詞
- 點例句中的英文片段 → 也唸出來（hover-to-speak）
- 點 related chip → push 該詞 detail

---

### 4.4 Quiz Tab 🎯

**Quiz session flow**
```
QuizSetupView
├─ 選題數 (5 / 10 / 20)
├─ 選題型 (EN→L1 / L1→EN / 混合)
├─ 選範圍 (全部 / 某分類 / 只 review)
└─ 開始 →
   QuizCardView (loop)
   └─ 結束 → QuizResultView
```

**QuizCardView 結構**
1. Progress bar (上方細長條)
2. 大字題目 (display-l)
3. 4 個答案按鈕（pill 形, 2×2 grid）
4. 答對：綠色閃 + ✅ + 1s 後 next
   答錯：搖晃 + 紅光（淡）+ 顯示正解 + 點任意 next
5. 🔊 icon 隨題目自動播一次 (if EN→L1)

**QuizResultView**
- 大字 `5/5` 或 `4/5`
- Confetti 動畫 (only if 滿分)
- streak 更新動畫
- 「再來一輪」/「回首頁」按鈕

---

### 4.5 Settings Tab ⚙️

**結構 (List sections)**

Section 1 — Learning
- UI Language (en / zh-TW / ja / ko / es / pt)
- Native Language (學習對照語言)
- Daily goal (3 / 5 / 10 / 20)

Section 2 — Audio
- Voice (auto en-US / en-GB)
- Speed (slow / normal / fast slider)
- Auto-play on detail open (toggle)

Section 3 — Appearance
- Theme (Auto / Light / Dark)
- Dynamic Type (跟隨系統)

Section 4 — Data
- Export progress (JSON)
- Reset all progress

Section 5 — About
- Version `1.0.0`
- Open source on GitHub (link)
- Privacy Policy (link)
- Acknowledgement: "Claude Code is a trademark of Anthropic PBC. This app is unofficial."
- Send feedback (mailto:)

---

## 5. 互動細節 (Interaction Notes)

### Audio playback
- 同一畫面同時只能播一個音
- 播放中 🔊 變 ⏸
- 失敗（如 voice not downloaded）→ Toast「請至 Settings → Accessibility → Spoken Content → Voices 下載 English voice」

### Haptics
- 答對 / mastered：`.success` impact
- 答錯：`.warning` 但非 `.error`（不焦慮）
- Card flip / tab switch：`.soft`

### Gestures
- Term Detail：左滑回前一詞，右滑下一詞（依 category 排序）
- Quiz card：搖晃 = skip（但記為錯）

### Empty states
- Browse 無搜尋結果：「找不到該詞，試試這些 →」+ 推薦 3 詞
- Quiz 無 due review：「今天都複習完了 🎉」+ 推薦 explore

---

## 6. 無障礙 (Accessibility)

- 所有按鈕 `accessibilityLabel` 雙語（VoiceOver 讀 UI 語言）
- 🔊 按鈕 label: "Play pronunciation of {term}"
- Color contrast ≥ 4.5:1 (WCAG AA)
- Touch target ≥ 44×44pt
- Reduce motion：disable confetti / shake，保留 fade

---

## 7. App Icon Concept

- 1024×1024 PNG
- 背景：紫色漸層 (`#7C5BFF` → `#5430E5`)
- 前景：白色書本圖示 + `/` 斜線符號（CLI 與書本結合）
- 簡潔，無文字（icon 不放 app name 是 Apple HIG 慣例）

---

## 8. App Store 截圖計畫

6 張，iPhone 6.7" (Pro Max)：
1. Today 畫面 + 「Learn the language of agentic coding」slogan
2. Term Detail (Slash Commands) + 「Real Claude Code vocabulary, with audio」
3. Quiz card + 「Multiple-choice quiz, spaced repetition」
4. Browse (Hooks category) + 「11 categories, 30+ terms growing」
5. Settings (language picker) + 「6 languages: EN / 繁中 / 日 / 韓 / 西 / 葡」
6. Dark mode + 「Beautiful in Light & Dark」

---

End of DESIGN.md v0.1
