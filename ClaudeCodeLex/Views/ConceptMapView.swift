// ConceptMapView.swift
// A walkable relationship map for a term: the focus term sits at the center,
// its `relatedTerms` orbit it as satellites joined by edges.
//
// Tap a satellite → it becomes the new center (the map re-lays-out).
// Tap the center → open that term's detail page.
// Walking node to node lets the user traverse the whole concept graph.

import SwiftUI

struct ConceptMapView: View {
    let startTerm: Term

    @EnvironmentObject var termStore: TermStore
    @EnvironmentObject var settings: AppSettings

    /// The term currently at the center — changes as the user walks the graph.
    @State private var focusID: String

    init(focus: Term) {
        startTerm = focus
        _focusID = State(initialValue: focus.id)
    }

    private var focus: Term? { termStore.term(by: focusID) }

    private var related: [Term] {
        (focus?.relatedTerms ?? []).compactMap { termStore.term(by: $0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            if !related.isEmpty {
                Text("conceptMap.hint")
                    .font(.rounded(13))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
            }

            GeometryReader { geo in
                let layout = graphLayout(in: geo.size, count: related.count)
                ZStack {
                    edges(center: layout.center, nodes: layout.nodes)
                    satellites(center: layout.center, nodes: layout.nodes)
                    centerNode(at: layout.center)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .id(focusID)
                .transition(.opacity.combined(with: .scale(scale: 0.94)))
            }
        }
        .background(AppColor.warmBg.ignoresSafeArea())
        .navigationTitle("conceptMap.title")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Pieces

    private func edges(center: CGPoint, nodes: [CGPoint]) -> some View {
        ForEach(Array(related.enumerated()), id: \.element.id) { idx, _ in
            Path { p in
                p.move(to: center)
                if idx < nodes.count { p.addLine(to: nodes[idx]) }
            }
            .stroke(AppColor.brandPrimary.opacity(0.3), lineWidth: 2)
        }
    }

    private func satellites(center: CGPoint, nodes: [CGPoint]) -> some View {
        ForEach(Array(related.enumerated()), id: \.element.id) { idx, term in
            Button {
                withAnimation(.easeInOut(duration: 0.35)) { focusID = term.id }
            } label: {
                nodeChip(term, isCenter: false)
            }
            .buttonStyle(.plain)
            .frame(minWidth: 44, minHeight: 44)   // HIG tap target for the satellite chip
            .contentShape(Rectangle())
            .accessibilityLabel(Text(term.english))
            .accessibilityHint(Text("conceptMap.hint"))
            .position(idx < nodes.count ? nodes[idx] : center)
        }
    }

    @ViewBuilder
    private func centerNode(at point: CGPoint) -> some View {
        if let f = focus {
            NavigationLink(value: f) {
                nodeChip(f, isCenter: true)
            }
            .buttonStyle(.plain)
            .position(point)
        }
    }

    private func nodeChip(_ term: Term, isCenter: Bool) -> some View {
        let bg: Color = isCenter ? AppColor.brandPrimary : AppColor.warmCard
        let fg: Color = isCenter ? .white : AppColor.brandPrimary
        return Text(term.english)
            .font(.rounded(isCenter ? 17 : 13, weight: isCenter ? .bold : .medium))
            .foregroundStyle(fg)
            .lineLimit(2)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: isCenter ? 150 : 110)
            .padding(.horizontal, isCenter ? 18 : 12)
            .padding(.vertical, isCenter ? 14 : 9)
            .background(bg)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppColor.brandPrimary.opacity(isCenter ? 0 : 0.3),
                                 lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
    }

    // MARK: - Geometry

    private struct GraphLayout {
        let center: CGPoint
        let nodes: [CGPoint]
    }

    /// Lays the satellites on an ellipse: `radiusX` is bound by the narrow
    /// screen width, `radiusY` by its height — so the map fills a tall phone
    /// instead of floating as a small circle. The center is nudged vertically
    /// so the (top-loaded) ring sits balanced in the available space.
    private func graphLayout(in size: CGSize, count: Int) -> GraphLayout {
        let midX = size.width / 2, midY = size.height / 2
        guard count > 0 else {
            return GraphLayout(center: CGPoint(x: midX, y: midY), nodes: [])
        }
        let angles = (0..<count).map {
            (2 * Double.pi * Double($0) / Double(count)) - .pi / 2
        }
        let coss = angles.map { CGFloat(cos($0)) }
        let sins = angles.map { CGFloat(sin($0)) }
        let maxCos = max(coss.map(abs).max() ?? 1, 0.001)
        let radiusX = (midX - 88) / maxCos       // 88 ≈ half widest chip + margin
        let radiusY = midY - 64
        // Include the center node (sin 0) so the vertical span stays balanced.
        let loSin = min(0, sins.min() ?? 0)
        let hiSin = max(0, sins.max() ?? 0)
        let center = CGPoint(x: midX, y: midY - radiusY * (loSin + hiSin) / 2)
        let nodes = (0..<count).map {
            CGPoint(x: center.x + radiusX * coss[$0],
                    y: center.y + radiusY * sins[$0])
        }
        return GraphLayout(center: center, nodes: nodes)
    }
}
