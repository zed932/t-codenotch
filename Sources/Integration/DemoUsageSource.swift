import Foundation

/// Synthetic in-memory values. This source performs no I/O.
struct DemoUsageSource: UsageSource {
    func fetchSnapshot() async throws -> UsageSnapshot {
        let now = Date()
        return try UsageSnapshot(title: "Демонстрация", limits: [
            UsageLimit(id: "short", title: "Короткое окно", usedFraction: 0.21,
                       resetsAt: now.addingTimeInterval(3_600)),
            UsageLimit(id: "long", title: "Длинное окно", usedFraction: 0.73,
                       resetsAt: now.addingTimeInterval(86_400)),
        ], measuredAt: now, validFor: 300)
    }
}
