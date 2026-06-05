// Term.swift  (schema v2)
// Term metadata is in terms.en.json; translations are in per-locale files (terms.{locale}.json).

import Foundation

// MARK: - Main bundle (terms.en.json)

struct TermsMainBundle: Decodable {
    let metadata: BundleMetadata
    let categories: [CategoryMeta]
    let terms: [Term]
}

struct BundleMetadata: Decodable {
    let version: String
    let updated: String
    let source: String?
    let supportedLocales: [String]
    let fullyTranslatedLocales: [String]
}

struct CategoryMeta: Decodable, Identifiable, Hashable {
    let id: String
    let icon: String
    let order: Int
    let names: [String: String]   // locale -> display

    func name(for locale: String) -> String {
        names[locale] ?? names["en"] ?? id
    }
}

struct Term: Decodable, Identifiable, Hashable {
    let id: String
    let english: String
    let category: String
    let pronunciation: String?
    let difficulty: Int
    let isEnglishOnly: Bool
    let tags: [String]
    let relatedTerms: [String]
    let addedDate: String?

    static func == (lhs: Term, rhs: Term) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

// MARK: - Per-locale bundle (terms.{locale}.json)

struct LocaleBundle: Decodable {
    let locale: String
    let translator: String?
    let lastUpdated: String
    let coverage: Coverage
    let tagline: String?
    let translations: [String: LocalizedTranslation]
}

struct Coverage: Decodable, Hashable {
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
    let realUse: String?          // an authentic snippet of the term in real usage
    let commonConfusion: String?  // how to tell it apart from a similar term
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
