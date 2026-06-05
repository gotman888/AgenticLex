// TipJarService.swift
// Voluntary, non-functional IAP. Three consumable tip tiers — no feature gates.
// Apple loves a clear business model; users get a way to say thanks.
//
// Setup in Xcode:
//   1. Add a StoreKit Configuration File (Tips.storekit, included in Resources/)
//      Product → Scheme → Edit Scheme → Run → Options → StoreKit Configuration
//   2. In App Store Connect, create 3 consumable IAPs with these product IDs:
//        com.gotman.agenticlex.tip.small   ($0.99 USD)
//        com.gotman.agenticlex.tip.medium  ($4.99 USD)
//        com.gotman.agenticlex.tip.large   ($19.99 USD)
//
// StoreKit 2 is iOS 15+. Pure async/await, no callbacks.

import Foundation
import StoreKit

enum TipTier: String, CaseIterable, Identifiable {
    case small  = "com.gotman.agenticlex.tip.small"
    case medium = "com.gotman.agenticlex.tip.medium"
    case large  = "com.gotman.agenticlex.tip.large"

    var id: String { rawValue }

    /// Approx USD amount, used for local lifetime tally only.
    /// Actual price comes from the StoreKit Product.
    var approxUSD: Double {
        switch self {
        case .small:  return 0.99
        case .medium: return 4.99
        case .large:  return 19.99
        }
    }

    var emoji: String {
        switch self {
        case .small:  return "☕"
        case .medium: return "🍔"
        case .large:  return "🎁"
        }
    }
}

@MainActor
final class TipJarService: ObservableObject {
    @Published private(set) var products: [Product] = []
    /// True while the initial (or a retried) product fetch is in flight.
    /// Starts true because `init` kicks off a load immediately.
    @Published private(set) var isLoading: Bool = true
    @Published private(set) var isPurchasing: Bool = false
    @Published private(set) var lastError: String?
    @Published private(set) var thankYouShown: Bool = false

    init() {
        Task { await loadProducts() }
    }

    func loadProducts() async {
        isLoading = true
        lastError = nil
        defer { isLoading = false }
        do {
            let ids = TipTier.allCases.map(\.rawValue)
            let fetched = try await Product.products(for: ids)
            // Sort by price ascending so UI shows small → large.
            self.products = fetched.sorted { $0.price < $1.price }
        } catch {
            self.lastError = "Could not load Tip Jar: \(error.localizedDescription)"
        }
    }

    /// Initiate a purchase. Updates lifetime tally on success.
    func purchase(_ tier: TipTier, settings: AppSettings) async {
        guard let product = products.first(where: { $0.id == tier.rawValue }) else {
            lastError = "Product not available."
            return
        }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    // Local tally; this is purely cosmetic for "thanks ❤️" UI
                    settings.tipJarLifetime += tier.approxUSD
                    thankYouShown = true
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
}
