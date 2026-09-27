import Foundation
import Combine

@MainActor
final class UsageStore: ObservableObject {
    enum Status: Equatable {
        case notConfigured, ready, failed
    }

    @Published private(set) var snapshot: UsageSnapshot?
    @Published private(set) var status: Status = .notConfigured
    @Published private(set) var isRefreshing = false
    @Published private(set) var isDemo: Bool
    private var source: any UsageSource
    private var generation = 0

    init(source: any UsageSource = UnconfiguredUsageSource(), isDemo: Bool = false) {
        self.source = source
        self.isDemo = isDemo
    }

    /// Always discard readings when changing sources, including demo → real.
    func replaceSource(_ source: any UsageSource, isDemo: Bool) {
        generation += 1
        self.source = source
        self.isDemo = isDemo
        snapshot = nil
        status = .notConfigured
        isRefreshing = false
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let requestGeneration = generation
        defer { if generation == requestGeneration { isRefreshing = false } }
        do {
            let value = try await source.fetchSnapshot()
            guard !Task.isCancelled, generation == requestGeneration else { return }
            // A future source timestamp cannot make stale readings appear fresh forever.
            guard value.measuredAt <= Date().addingTimeInterval(60) else {
                throw UsageSourceError.invalidData
            }
            snapshot = value
            status = .ready
        } catch {
            guard !Task.isCancelled, generation == requestGeneration else { return }
            if (error as? UsageSourceError) == .notConfigured {
                snapshot = nil
                status = .notConfigured
            } else {
                // Never expose a transport's raw error: it may contain a URL or secret.
                status = .failed
            }
        }
    }

    func message(at now: Date) -> String {
        if isRefreshing { return "Обновление…" }
        switch status {
        case .notConfigured: return "Источник не подключён"
        case .failed: return snapshot == nil ? "Данные недоступны" : "Не удалось обновить · прежние данные"
        case .ready:
            if snapshot?.isStale(at: now) == true { return "Данные устарели" }
            return isDemo ? "Демонстрационные данные" : "Данные получены"
        }
    }

    func isStale(at now: Date) -> Bool {
        status == .failed || snapshot?.isStale(at: now) == true
    }
}
