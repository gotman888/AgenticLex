// ReviewSessionView.swift
// Simple linear "review" mode (used by Today's "Start" button).

import SwiftUI

/// Simple linear "review" mode (used by Today's "Start" button)
struct ReviewSessionView: View {
    let terms: [Term]
    @State private var index: Int = 0

    var body: some View {
        if index < terms.count {
            TermDetailView(term: terms[index])
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("review.next") {
                            index += 1
                        }
                    }
                }
        } else {
            VStack(spacing: 16) {
                Text("🎉").font(.system(size: 64))
                Text("review.done")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
