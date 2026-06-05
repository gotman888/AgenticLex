// KeychainHelper.swift
// Generic-password keychain wrapper for storing API keys.
// API keys are NEVER stored in UserDefaults / file system.

import Foundation
import Security

enum KeychainHelper {
    /// Top-level service identifier. Keychain entries are scoped to this string.
    static let service = "com.gotman.agenticlex.apikey"

    @discardableResult
    static func save(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        // Delete any existing entry first (idempotent save)
        delete(account: account)

        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
            kSecValueData as String:       data,
            // Only accessible after first device unlock — survives reboots
            kSecAttrAccessible as String:  kSecAttrAccessibleAfterFirstUnlock
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    static func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account,
            kSecReturnData as String:      true,
            kSecMatchLimit as String:      kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let str = String(data: data, encoding: .utf8)
        else { return nil }
        return str
    }

    @discardableResult
    static func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String:           kSecClassGenericPassword,
            kSecAttrService as String:     service,
            kSecAttrAccount as String:     account
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }

    /// Convenience: redact key for UI display, e.g. `sk-abcd••••••wxyz`
    static func redacted(_ key: String) -> String {
        guard key.count > 8 else { return String(repeating: "•", count: max(key.count, 1)) }
        let head = key.prefix(4)
        let tail = key.suffix(4)
        return "\(head)\(String(repeating: "•", count: 8))\(tail)"
    }
}
