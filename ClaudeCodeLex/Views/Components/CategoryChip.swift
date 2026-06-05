// CategoryChip.swift

import SwiftUI

struct CategoryChip: View {
    let label: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(selected ? AppColor.brandPrimary : AppColor.brandPrimary.opacity(0.12))
                .foregroundStyle(selected ? .white : AppColor.brandPrimary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
