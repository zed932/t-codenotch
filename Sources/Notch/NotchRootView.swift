import SwiftUI

struct NotchRootView: View {
    @ObservedObject var model: NotchViewModel
    @ObservedObject var store: UsageStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let metrics = model.metrics
            let bar = metrics.bar(expanded: model.expanded)
            ZStack(alignment: .topLeading) {
                SideNotchShape(edge: model.edge,
                               curlRadius: model.expanded ? NotchLayout.curlRadius * model.scale : 8,
                               cornerRadius: model.expanded ? NotchLayout.cornerRadius * model.scale : 5)
                    .fill(Palette.notch)
                    .frame(width: bar.width, height: bar.height)
                    .position(x: bar.midX, y: bar.midY)
                if model.expanded {
                    ForEach(0..<max(store.snapshot?.limits.count ?? 0, 1), id: \.self) { index in
                        let rect = metrics.cellRect(index)
                        UsageRing(limit: store.snapshot?.limits[index], stale: store.isStale(at: context.date), demo: store.isDemo)
                            .scaleEffect(model.scale)
                            .frame(width: rect.width, height: rect.height)
                            .position(x: rect.midX, y: rect.midY)
                    }
                    Button { model.onSettings?() } label: {
                        Image(systemName: "gearshape").foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .frame(width: metrics.settingsRect.width, height: metrics.settingsRect.height)
                    .position(x: metrics.settingsRect.midX, y: metrics.settingsRect.midY)
                    .accessibilityLabel("Настройки")
                    if let index = model.hoveredIndex {
                        UsageCard(store: store, limit: store.snapshot?.limits.indices.contains(index) == true ? store.snapshot?.limits[index] : nil,
                                  now: context.date)
                            .position(x: metrics.card.midX, y: metrics.card.midY)
                    }
                }
            }
            .frame(width: metrics.size.width, height: metrics.size.height)
            .animation(reduceMotion ? nil : NotchMotion.unfold, value: model.expanded)
        }
    }
}
