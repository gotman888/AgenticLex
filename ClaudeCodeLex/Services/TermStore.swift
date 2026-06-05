// TermStore.swift  (schema v2)
// Loads main bundle (terms.en.json) plus per-locale translation bundles.

import Foundation
import Combine

@MainActor
final class TermStore: ObservableObject {
    @Published private(set) var main: TermsMainBundle?
    @Published private(set) var localeBundles: [String: LocaleBundle] = [:]
    @Published private(set) var loadError: String?

    init() {
        purgeStaleDownloadsIfAppUpdated()
        loadMain()
        ensureLocale("en")
        // Pre-warm the user's saved native locale at launch so the first Browse /
        // Today row body doesn't synchronously decode a locale JSON mid-scroll.
        // (First launch has none persisted yet → only en, which is fine.)
        // @AppStorage doesn't persist its default until first written, so on a
        // fresh non-en device the key is absent — fall back to the same detector
        // AppSettings uses so the pre-warm actually fires on first launch too.
        let native = UserDefaults.standard.string(forKey: "learning.nativeLanguage")
            ?? AppSettings.autoDetectLocale()
        if native != "en" { ensureLocale(native) }
    }

    // MARK: - Loading

    private func loadMain() {
        guard let url = resourceURL(for: "terms.en") else {
            loadError = "terms.en.json not found"
            return
        }
        do {
            let data = try Data(contentsOf: url)
            self.main = try JSONDecoder().decode(TermsMainBundle.self, from: data)
        } catch {
            loadError = "Decode terms.en.json failed: \(error)"
        }
    }

    /// Load translation bundle for the given locale on demand (idempotent).
    func ensureLocale(_ locale: String) {
        if localeBundles[locale] != nil { return }
        guard let url = resourceURL(for: "terms.\(locale)") else {
            // Missing bundle — not fatal, callers will fall back.
            return
        }
        if let data = try? Data(contentsOf: url),
           let bundle = try? JSONDecoder().decode(LocaleBundle.self, from: data) {
            localeBundles[locale] = bundle
        }
    }

    // MARK: - Resource resolution (OTA-aware)

    /// URL for a term JSON — prefers an OTA-downloaded copy in Documents,
    /// falling back to the file bundled with the app.
    private func resourceURL(for resource: String) -> URL? {
        let downloaded = TermUpdateService.documentsURL(resource)
        if FileManager.default.fileExists(atPath: downloaded.path) { return downloaded }
        return Bundle.main.url(forResource: resource, withExtension: "json")
    }

    /// If the app binary changed since the last OTA download, drop the
    /// downloaded dictionary so the (at-least-as-fresh) bundled copy wins.
    /// A later opt-in update check re-fetches if the remote is still newer.
    private func purgeStaleDownloadsIfAppUpdated() {
        let defaults = UserDefaults.standard
        guard let stamped = defaults.string(forKey: "dict.downloadedBuild"),
              stamped != TermUpdateService.currentBuild else { return }
        for name in TermUpdateService.fileNames {
            try? FileManager.default.removeItem(at: TermUpdateService.documentsURL(name))
        }
        defaults.removeObject(forKey: "dict.downloadedBuild")
        defaults.removeObject(forKey: "dict.downloadedVersion")
    }

    // MARK: - Queries: terms

    var allTerms: [Term] { main?.terms ?? [] }

    var categories: [CategoryMeta] {
        (main?.categories ?? []).sorted { $0.order < $1.order }
    }

    func term(by id: String) -> Term? {
        main?.terms.first { $0.id == id }
    }

    func terms(in categoryId: String?) -> [Term] {
        guard let cid = categoryId else { return allTerms }
        return allTerms.filter { $0.category == cid }
    }

    // MARK: - Queries: translation

    /// Returns the translation for `termId` in `locale`, falling back to en, then to a "missing" placeholder.
    func translation(for termId: String, locale: String) -> LocalizedTranslation {
        ensureLocale(locale)
        if let t = localeBundles[locale]?.translations[termId] { return t }
        if locale != "en", let t = localeBundles["en"]?.translations[termId] { return t }
        if let term = term(by: termId) {
            return LocalizedTranslation(
                term: term.english,
                definition: "(Translation coming soon — help us at github.com/gotman888/AgenticLex)",
                example: "",
                memoryHook: nil,
                realUse: nil,
                commonConfusion: nil,
                status: .missing,
                translator: nil,
                updated: nil
            )
        }
        return LocalizedTranslation(
            term: termId, definition: "", example: "",
            memoryHook: nil, realUse: nil, commonConfusion: nil,
            status: .missing, translator: nil, updated: nil
        )
    }

    // MARK: - Queries: locale metadata

    /// Whether the locale's translation coverage is "fully translated" per main bundle declaration.
    func isFullyTranslated(_ locale: String) -> Bool {
        main?.metadata.fullyTranslatedLocales.contains(locale) ?? false
    }

    /// Per-locale marketing tagline. Falls back to en's tagline, then to the app default.
    func tagline(for locale: String) -> String {
        ensureLocale(locale)
        if let s = localeBundles[locale]?.tagline { return s }
        if let s = localeBundles["en"]?.tagline    { return s }
        return NSLocalizedString("app.tagline", comment: "")
    }

    func coverage(for locale: String) -> Coverage? {
        ensureLocale(locale)
        return localeBundles[locale]?.coverage
    }

    // MARK: - Search

    /// Searches across English term, id, tags, and the localized term in `locale`.
    func search(_ query: String, locale: String) -> [Term] {
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return allTerms }
        ensureLocale(locale)
        return allTerms.filter { t in
            if t.english.lowercased().contains(q) { return true }
            if t.id.contains(q) { return true }
            if t.tags.contains(where: { $0.lowercased().contains(q) }) { return true }
            let tr = translation(for: t.id, locale: locale)
            if tr.term.lowercased().contains(q) { return true }
            return false
        }
    }
}
