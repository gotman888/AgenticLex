# 📚 docs/ — 章節導覽

> 所有設計與規格文件的目錄。
> 給人類讀者照需求挑章節翻。

---

## 🟢 必讀（從這裡開始）

| # | 文件 | 何時讀 |
|---|---|---|
| ★ | [../README.md](../README.md) | **第一份**，專案總覽 |
| ★ | [../CLAUDE.md](../CLAUDE.md) | Claude Code 啟動自動讀，人類不必逐字看 |
| ★ | [../CHANGELOG.md](../CHANGELOG.md) | 想知道每版做了什麼 |
| ★ | [./ROADMAP.md](./ROADMAP.md) | 想知道接下來要做什麼 |
| ★ | [./ARCHITECTURE.md](./ARCHITECTURE.md) | 想了解 codebase 結構 |

---

## 🔵 規格設計（需要時翻）

| 文件 | 主題 | 何時翻 |
|---|---|---|
| [./PRD.md](./PRD.md) | 產品需求書 | 想知道「為什麼做這個 app」 |
| [./DESIGN.md](./DESIGN.md) | UI/UX 設計規格 | 改畫面時 |
| [./SCHEMA_V2.md](./SCHEMA_V2.md) | terms.json 結構 | 加詞 / 改 schema 時 |

---

## 🟣 哲學與策略（深度設計）

| 文件 | 主題 | 何時翻 |
|---|---|---|
| [./FRIENDLY_LEARNING.md](./FRIENDLY_LEARNING.md) | Lexi 吉祥物與學習哲學 | 想做 UX 改進時 |
| [./AI_BYOK_DESIGN.md](./AI_BYOK_DESIGN.md) | BYOK 七維度與技術架構 | 加新 AI provider 時 |
| [./OPTIMIZATION.md](./OPTIMIZATION.md) | 30+ 條改進建議分 P0-P3 | 想知道還能優化哪裡 |

---

## 🟠 上架與運營

| 文件 | 主題 | 何時翻 |
|---|---|---|
| [./APPSTORE_METADATA.md](./APPSTORE_METADATA.md) | 6 語系 App Store 文案 | App Store Connect 填表時 |

---

## 🎨 視覺資產

| 路徑 | 內容 |
|---|---|
| [../wireframe/index.html](../wireframe/index.html) | 5 個畫面互動 HTML mockup |

---

## 📖 推薦閱讀順序（給新接手者）

```
1. ../README.md            (5 分鐘) — 專案總覽
2. ../CHANGELOG.md         (5 分鐘) — 演進歷程
3. ./ROADMAP.md            (10 分鐘) — 接下來要做什麼
4. ./ARCHITECTURE.md       (15 分鐘) — codebase 拆解
5. ../wireframe/index.html (5 分鐘) — 視覺感覺
─────────────────────────────────────────
總計 40 分鐘可掌握全貌
```

更深入時再翻 §🔵 §🟣 §🟠。

---

## 📖 推薦閱讀順序（給 Claude Code）

Claude Code 啟動會自動讀 `../CLAUDE.md`，那份已含必要 context。
若 user 問特定主題，按 user 意圖挑章節翻：

| User 問 | Claude 應翻 |
|---|---|
| 「加新詞」 | SCHEMA_V2.md + ROADMAP §2.1 |
| 「改 UI 配色」 | DESIGN.md + FRIENDLY_LEARNING.md |
| 「加新 AI provider」 | AI_BYOK_DESIGN.md + ARCHITECTURE §8 |
| 「優化某功能」 | OPTIMIZATION.md |
| 「上架準備」 | APPSTORE_METADATA.md + ROADMAP §4-6 |
| 「畫面長怎樣」 | DESIGN.md + wireframe/index.html |

---

End of INDEX.md
