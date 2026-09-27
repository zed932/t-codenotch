import Foundation

/// Implement this interface inside the approved environment. No transport is assumed.
protocol UsageSource: Sendable {
    func fetchSnapshot() async throws -> UsageSnapshot
}

enum UsageSourceError: Error, Equatable {
    case notConfigured
    case unavailable
    case invalidData
}

/// Deliberately inert. Replacing this implementation is the integration seam.
struct UnconfiguredUsageSource: UsageSource {
    func fetchSnapshot() async throws -> UsageSnapshot {
        throw UsageSourceError.notConfigured
    }
}

enum UsageSourceFactory {
    static func makeSource(demo: Bool) -> any UsageSource {
        demo ? DemoUsageSource() : UnconfiguredUsageSource()
    }
}
