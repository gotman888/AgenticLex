// TermUpdateService.swift
// Optional over-the-air dictionary updates. When the user opts in
// (Settings → Auto-update dictionary, OFF by default), the app checks a
// static, GitHub-hosted copy of the term files and downloads a newer set
// into Documents. No server, no tracking — a plain GET of static JSON,
// and only ever when the user has switched it on. The app remains fully
// usable offline; this just lets the dictionary grow between releases.

import Foundation

@MainActor
final class TermUpdateService: ObservableObject {
    static let shared = TermUpdateService()
    private init() {}

    enum Status: Equatable { case idle, checking, upToDate, updated, failed }
    @Published private(set) var status: Status = .idle

    /// Where the published dictionary lives. The hosted folder must contain
    /// terms.en.json and every per-locale file. Static hosting only.
    /// TODO(owner): publish the term JSON files at this path.
    private let baseURL = URL(string: "https://gotman888.github.io/agenticlex-docs/dict/")!

    /// The term files the app ships (terms.en.json is main bundle + en locale).
    static let fileNames = ["terms.en", "terms.zh-TW", "terms.zh-CN",
                            "terms.ja", "terms.ko", "terms.es", "terms.pt"]

    /// Checks the remote terms.en.json version; if it is newer than
    /// `currentVersion`, downloads the whole set into Documents. The new
    /// dictionary is picked up on the next launch.
    func check(currentVersion: String) async {
        guard status != .checking else { return }
        status = .checking
        do {
            let remote = try await fetchJSON("terms.en")
            guard let meta = remote["metadata"] as? [String: Any],
                  let remoteVersion = meta["version"] as? String else {
                status = .failed; return
            }
            guard Self.isNewer(remoteVersion, than: currentVersion) else {
                status = .upToDate; return
            }
            var gotMain = false
            for name in Self.fileNames {
                guard let data = try? await fetchData(name) else { continue }
                try? data.write(to: Self.documentsURL(name), options: .atomic)
                if name == "terms.en" { gotMain = true }
            }
            guard gotMain else { status = .failed; return }
            let defaults = UserDefaults.standard
            defaults.set(remoteVersion, forKey: "dict.downloadedVersion")
            defaults.set(Self.currentBuild, forKey: "dict.downloadedBuild")
            status = .updated
        } catch {
            status = .failed
        }
    }

    // MARK: - Helpers

    static func documentsURL(_ name: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("\(name).json")
    }

    static var currentBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    }

    private func fetchData(_ name: String) async throws -> Data {
        var req = URLRequest(url: baseURL.appendingPathComponent("\(name).json"))
        req.cachePolicy = .reloadIgnoringLocalCacheData
        req.timeoutInterval = 20
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    private func fetchJSON(_ name: String) async throws -> [String: Any] {
        let data = try await fetchData(name)
        guard let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        return obj
    }

    /// Dot-separated numeric version compare ("2.1" is newer than "2.0").
    static func isNewer(_ a: String, than b: String) -> Bool {
        let pa = a.split(separator: ".").map { Int($0) ?? 0 }
        let pb = b.split(separator: ".").map { Int($0) ?? 0 }
        for i in 0..<max(pa.count, pb.count) {
            let x = i < pa.count ? pa[i] : 0
            let y = i < pb.count ? pb[i] : 0
            if x != y { return x > y }
        }
        return false
    }
}
