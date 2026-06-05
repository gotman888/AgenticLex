// BrowseView.swift
// Browse tab — search + category filter + term list.

import SwiftUI

struct BrowseView: View {
    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var settings: AppSettings

    @State private var searchText: String = ""
    @State private var selectedCategory: String? = nil // nil == All

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                categoryChips

                if filteredTerms.isEmpty && !searchText.isEmpty {
                    emptyResults
                } else {
                    List(filteredTerms) { term in
                        NavigationLink(value: term) {
                            TermRow(term: term)
                        }
                        .listRowSeparator(.visible)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .background(AppColor.warmBg.ignoresSafeArea())
            .navigationDestination(for: Term.self) { term in
                TermDetailView(term: term)
            }
            .searchable(text: $searchText, prompt: Text("browse.searchPrompt"))
            .navigationTitle("browse.tab")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        LearningPathView()
                    } label: {
                        Image(systemName: "flag.checkered")
                    }
                    .accessibilityLabel(Text("path.title"))
                }
            }
        }
    }

    private var emptyResults: some View {
        VStack(spacing: 16) {
            Spacer()
            LexiView(pose: .sleepy, size: 72)
            Text("browse.noResults")
                .font(.rounded(16, weight: .medium))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var filteredTerms: [Term] {
        let base = termStore.terms(in: selectedCategory)
        guard !searchText.isEmpty else { return base }
        let q = searchText.lowercased()
        return base.filter { t in
            if t.english.lowercased().contains(q) { return true }
            let tr = termStore.translation(for: t.id, locale: settings.nativeLanguage).term
            return tr.lowercased().contains(q)
        }
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                CategoryChip(
                    label: NSLocalizedString("category.all", comment: ""),
                    selected: selectedCategory == nil
                ) { selectedCategory = nil }

                ForEach(termStore.categories) { cat in
                    CategoryChip(
                        label: cat.name(for: settings.uiLanguage),
                        selected: selectedCategory == cat.id
                    ) {
                        selectedCategory = (selectedCategory == cat.id) ? nil : cat.id
                    }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}
