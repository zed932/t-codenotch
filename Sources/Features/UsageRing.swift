import SwiftUI

struct UsageRing: View {
    let limit: UsageLimit?
    var stale = false
    var demo = false
    private var color: Color { stale ? Palette.textSecondary : Palette.usage(limit?.usedFraction) }

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle().stroke(Palette.ringTrack, lineWidth: 4)
                if let value = limit?.usedFraction {
                    Circle().trim(from: 0, to: min(value, 1))
                        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                Image(systemName: demo ? "circle.dotted" : "chart.bar")
                    .font(.system(size: 17, weight: .medium)).foregroundStyle(.white)
            }.frame(width: 38, height: 38)
            Text(limit?.percentage ?? "—").font(Typography.percent).foregroundStyle(color)
            if demo { Text("ДЕМО").font(.system(size: 8, weight: .bold)).foregroundStyle(Palette.textSecondary) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(demo ? "Демонстрация. " : "")\(limit?.title ?? "Лимит"): \(limit?.percentage ?? "нет данных")\(stale ? ". Устаревшие данные" : "")")
    }
}
