# terms.json schema v2 — 升級提案

> 對應 OPTIMIZATION.md B3 / B5 / B6 / B7
> v1 → v2 是 backward-compatible 升級，舊 decoder 可繼續用

---

## 1. 為何升級

| 痛點 v1 | 解法 v2 |
|---|---|
| 無法標示「英文不譯」的詞 (如 MCP) | 加 `isEnglishOnly` flag |
| 翻譯品質無分級，AI 翻和人工翻看不出來 | translation 加 `status` 欄 |
| 一檔包山包海，社群 PR 衝突 | 拆成 `terms.en.json` + `terms.{locale}.json` |
| 無從追蹤誰翻的、何時翻的 | translation 加 `translator` / `updated` |
| App Store 描述每語系該不同訴求，無處放 | metadata 加 `taglineByLocale` |

---

## 2. 檔案結構 v2

```
Resources/
├── terms.en.json          (主檔，含 metadata + categories + 英文 + 元資料)
├── terms.zh-TW.json       (僅翻譯內容，依 term.id 對應)
├── terms.ja.json
├── terms.ko.json
├── terms.es.json
└── terms.pt.json
```

**好處**
1. 加新詞只動 en 檔，其他語系自動標 missing
2. 各語系獨立 PR，無衝突
3. App 啟動只 load 該 user 需要的 locale，記憶體更省

---

## 3. terms.en.json (主檔) schema

```jsonc
{
  "$schema": "2.0.0",
  "metadata": {
    "version": "2.0.0",
    "updated": "2026-05-20",
    "supportedLocales": ["en", "zh-TW", "ja", "ko", "es", "pt"],
    "fullyTranslatedLocales": ["en", "zh-TW"]
  },

  "categories": [
    {
      "id": "cli",
      "icon": "terminal",
      "order": 1,
      "names": {
        "en": "CLI Basics",
        "zh-TW": "指令列基礎",
        "ja": "CLI 基礎",
        "ko": "CLI 기초",
        "es": "CLI",
        "pt": "CLI"
      }
    }
    // ...
  ],

  "terms": [
    {
      "id": "mcp",
      "english": "MCP",
      "category": "mcp",
      "pronunciation": "/ɛm siː piː/",
      "alternativePronunciations": ["/ˈmɛm siː piː/", "MCP (em see pee)"],
      "difficulty": 2,
      "isEnglishOnly": true,         // 新欄位：永遠保留英文
      "tags": ["mcp", "protocol"],
      "relatedTerms": ["mcp-server", "tool"],
      "firstSeenIn": "Claude Code v1.0",
      "addedDate": "2026-05-20"
      // 注意：translations 移到各語系檔
    }
  ]
}
```

---

## 4. terms.zh-TW.json (語系檔) schema

```jsonc
{
  "$schema": "2.0.0",
  "locale": "zh-TW",
  "translator": "王宏盟",
  "lastUpdated": "2026-05-20",
  "coverage": {
    "totalTerms": 30,
    "translated": 30,
    "verified": 28,
    "ai": 2,
    "missing": 0
  },
  "tagline": "讀懂 AI 編程的英文",  // 新欄位：本語系專屬 marketing copy
  "translations": {
    "mcp": {
      "term": "MCP (模型上下文協定)",
      "definition": "Model Context Protocol 的縮寫...",
      "example": "...",
      "memoryHook": "M = Model...",
      "status": "verified",           // verified / ai / missing
      "translator": "王宏盟",
      "updated": "2026-05-20"
    },
    "slash-command": {
      "term": "斜線指令",
      "definition": "...",
      "example": "...",
      "memoryHook": "...",
      "status": "verified",
      "translator": "王宏盟",
      "updated": "2026-05-20"
    }
    // ...
  }
}
```

---

## 5. terms.ja.json (社群協助範例)

```jsonc
{
  "$schema": "2.0.0",
  "locale": "ja",
  "translator": "TBD",
  "lastUpdated": "2026-05-19",
  "coverage": {
    "totalTerms": 30,
    "translated": 12,
    "verified": 0,
    "ai": 12,
    "missing": 18
  },
  "tagline": "AI コーディングの言葉を、君のものに",
  "translations": {
    "mcp": {
      "term": "MCP",
      "definition": "Model Context Protocol の略...",
      "example": "...",
      "memoryHook": null,
      "status": "ai",
      "translator": "claude-sonnet-4-6",
      "updated": "2026-05-19"
      // user 看到時 UI 上會顯示 "🤖 AI translation - help us verify!"
    }
    // 沒翻的 term 直接不出現在這個檔
  }
}
```

---

## 6. Swift 端 Model 升級

### Term.swift (拆 main + translation bundle)

```swift
// Main bundle (from terms.en.json)
struct TermsMainBundle: Decodable {
    let metadata: BundleMetadata
    let categories: [CategoryV2]
    let terms: [TermV2]
}

struct BundleMetadata: Decodable {
    let version: String
    let updated: String
    let supportedLocales: [String]
    let fullyTranslatedLocales: [String]
}

struct CategoryV2: Decodable, Identifiable, Hashable {
    let id: String
    let icon: String
    let order: Int
    let names: [String: String]   // locale -> display name

    func name(for locale: String) -> String {
        names[locale] ?? names["en"] ?? id
    }
}

struct TermV2: Decodable, Identifiable, Hashable {
    let id: String
    let english: String
    let category: String
    let pronunciation: String?
    let difficulty: Int
    let isEnglishOnly: Bool       // 新欄位
    let tags: [String]
    let relatedTerms: [String]
    let firstSeenIn: String?
    let addedDate: String?
}

// Translation bundle (from terms.{locale}.json)
struct LocaleBundle: Decodable {
    let locale: String
    let translator: String?
    let lastUpdated: String
    let coverage: Coverage
    let tagline: String?
    let translations: [String: LocalizedTranslation]
}

struct Coverage: Decodable {
    let totalTerms: Int
    let translated: Int
    let verified: Int
    let ai: Int
    let missing: Int

    var percentVerified: Double {
        guard totalTerms > 0 else { return 0 }
        return Double(verified) / Double(totalTerms) * 100
    }
}

struct LocalizedTranslation: Decodable, Hashable {
    let term: String
    let definition: String
    let example: String
    let memoryHook: String?
    let status: TranslationStatus
    let translator: String?
    let updated: String?
}

enum TranslationStatus: String, Decodable, Hashable {
    case verified
    case ai
    case missing

    var isReliable: Bool { self == .verified }
}
```

### TermStore.swift (拆分載入)

```swift
@MainActor
final class TermStoreV2: ObservableObject {
    @Published private(set) var main: TermsMainBundle?
    @Published private(set) var localeBundles: [String: LocaleBundle] = [:]

    func loadAll(uiLocale: String, nativeLocale: String) {
        // 1. Always load main
        main = loadJSON("terms.en")

        // 2. Load only the locales we need
        let need = Set([uiLocale, nativeLocale, "en"])
        for loc in need {
            if let bundle: LocaleBundle = loadJSON("terms.\(loc)") {
                localeBundles[loc] = bundle
            }
        }
    }

    /// Get translation with fallback chain:
    ///   nativeLocale -> "en" -> a fake "missing" placeholder
    func translation(for termId: String, locale: String) -> LocalizedTranslation {
        if let t = localeBundles[locale]?.translations[termId] {
            return t
        }
        // fallback: show English term itself as translation
        if let term = main?.terms.first(where: { $0.id == termId }) {
            return LocalizedTranslation(
                term: term.english,
                definition: "(Translation coming soon — help us at github.com/...)",
                example: "",
                memoryHook: nil,
                status: .missing,
                translator: nil,
                updated: nil
            )
        }
        return placeholderTranslation()
    }

    /// UI 顯示 coverage badge 用
    func coverageBadge(for locale: String) -> String {
        guard let bundle = localeBundles[locale] else { return "?" }
        return "\(Int(bundle.coverage.percentVerified))% verified"
    }
}
```

### TermDetailView 加 status badge

```swift
// 翻譯 block 標題列
HStack {
    Text("detail.translation")
    Spacer()
    if translation.status == .ai {
        Label("🤖 AI", systemImage: "exclamationmark.bubble")
            .font(.caption)
            .foregroundStyle(.orange)
    } else if translation.status == .missing {
        Label("Help translate", systemImage: "globe")
            .font(.caption)
            .foregroundStyle(.blue)
    }
}
```

### isEnglishOnly 視覺處理

```swift
// 在 TermDetailView hero
if term.isEnglishOnly {
    Text("term.englishOnly.note")  // "此術語業界慣用英文，建議直接記憶"
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.orange.opacity(0.12))
        .foregroundStyle(.orange)
        .clipShape(Capsule())
}
```

---

## 7. 遷移路徑 (v1 → v2)

**Phase 1 (v1.0 ship)**：保持 v1 結構，只加 `isEnglishOnly` flag (backward compat)

**Phase 2 (v1.1)**：拆檔，但 reader 同時支援 v1 / v2

**Phase 3 (v1.2)**：完全 v2，棄 v1

---

## 8. Schema 驗證

寫一個 `scripts/validate_terms.py`（之後做）：
- 檢查每個 locale 檔的 keys 是否都對應到 main 的 term.id
- 統計 coverage
- 檢查 status 是否合法
- 生產 README 用 coverage badge：`![zh-TW](https://...badge.svg)`

---

End of SCHEMA_V2.md
