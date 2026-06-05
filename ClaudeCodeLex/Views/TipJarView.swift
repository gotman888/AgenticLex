// TipJarView.swift
// Settings → "Support development" → presented sheet with 3 buttons.
// No functional gating; this is pure thanks.

import SwiftUI
import StoreKit

struct TipJarView: View {
    @EnvironmentObject var settings: AppSettings
    @StateObject private var service = TipJarService()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header

                    if service.isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity, minHeight: 200)
                    } else if service.products.isEmpty {
                        unavailableState
                    } else {
                        VStack(spacing: 12) {
                            ForEach(TipTier.allCases) { tier in
                                tipButton(for: tier)
                            }
                        }
                        .padding(.horizontal, 16)
                    }

                    if settings.tipJarLifetime > 0 {
                        Text(String(format: NSLocalizedString("tipjar.lifetimeFmt", comment: ""),
                                    settings.tipJarLifetime))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Load failures surface in `unavailableState`; this only
                    // catches purchase-time errors (products already loaded).
                    if !service.products.isEmpty, let err = service.lastError {
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    Text("tipjar.note")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.top, 12)
                }
                .padding(.vertical, 24)
            }
            .navigationTitle("tipjar.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("common.cancel") { dismiss() }
                }
            }
            .alert("tipjar.thanks.title",
                   isPresented: .constant(service.thankYouShown),
                   actions: {
                       Button("common.ok") { dismiss() }
                   },
                   message: {
                       Text("tipjar.thanks.body")
                   })
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("☕").font(.system(size: 60))
            Text("tipjar.title")
                .font(.title.bold())
            Text("tipjar.subtitle")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }

    /// Shown when the product fetch finished but returned nothing
    /// (no StoreKit config, no network, App Store hiccup). Offers a retry
    /// instead of spinning forever.
    private var unavailableState: some View {
        VStack(spacing: 12) {
            Text("tipjar.unavailable")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("common.retry") {
                Task { await service.loadProducts() }
            }
            .buttonStyle(.bordered)
            .tint(AppColor.brandPrimary)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, 24)
    }

    private func tipButton(for tier: TipTier) -> some View {
        let product = service.products.first(where: { $0.id == tier.rawValue })
        return Button {
            Task { await service.purchase(tier, settings: settings) }
        } label: {
            HStack {
                Text(tier.emoji).font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(product?.displayName ?? tier.rawValue)
                        .font(.headline)
                    Text(tipDescription(for: tier))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(product?.displayPrice ?? "—")
                    .font(.headline)
                    .foregroundStyle(AppColor.brandPrimary)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .disabled(service.isPurchasing)
    }

    private func tipDescription(for tier: TipTier) -> LocalizedStringKey {
        switch tier {
        case .small:  return "tipjar.tier.small"
        case .medium: return "tipjar.tier.medium"
        case .large:  return "tipjar.tier.large"
        }
    }
}
