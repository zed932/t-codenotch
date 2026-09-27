import SwiftUI

struct UsageCard: View {
    @ObservedObject var store: UsageStore
    let limit: UsageLimit?
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(limit?.title ?? "Лимиты").font(.headline).lineLimit(2)
                Spacer()
                if store.isDemo { Text("ДЕМО").font(.caption.bold()).foregroundStyle(Palette.watch) }
            }
            Text(store.message(at: now)).font(.caption).foregroundStyle(Palette.textSecondary)
            if let limit {
                HStack {
                    Text("Использовано")
                    Spacer()
                    Text(limit.percentage).monospacedDigit()
                }.font(.subheadline)
                if let fraction = limit.usedFraction {
                    ProgressView(value: min(fraction, 1)).tint(Palette.usage(fraction))
                }
                if let reset = limit.resetsAt {
                    Text(reset > now ? "Сброс: \(reset.formatted(date: .abbreviated, time: .shortened))" : "Время сброса прошло · обновите данные")
                        .font(.caption).foregroundStyle(Palette.textSecondary)
                }
                if let measured = store.snapshot?.measuredAt {
                    Text("Получены: \(measured.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2).foregroundStyle(Palette.textSecondary)
                }
            } else {
                Text("Показания появятся после подключения источника.")
                    .font(.subheadline).foregroundStyle(Palette.textSecondary)
            }
            Spacer(minLength: 0)
            Button("Обновить") { Task { await store.refresh() } }
                .disabled(store.isRefreshing)
                .buttonStyle(.borderless)
        }
        .padding(18)
        .frame(width: NotchLayout.cardSize.width, height: NotchLayout.cardSize.height)
        .background(Palette.card, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(.white.opacity(0.15)))
        .foregroundStyle(.white)
        .environment(\.colorScheme, .dark)
    }
}
