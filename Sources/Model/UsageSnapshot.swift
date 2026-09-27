import Foundation

/// The integration boundary carries quota numbers only: no accounts, paths or credentials.
struct UsageLimit: Identifiable, Equatable, Sendable {
    let id: String
    let title: String
    let usedFraction: Double?
    let resetsAt: Date?

    init(id: String, title: String, usedFraction: Double?, resetsAt: Date? = nil) throws {
        guard !id.isEmpty, id.count <= 80, !title.isEmpty, title.count <= 80,
              usedFraction.map({ $0.isFinite && $0 >= 0 && $0 <= 1_000 }) ?? true,
              resetsAt.map({ $0.timeIntervalSince1970.isFinite }) ?? true else {
            throw UsageSourceError.invalidData
        }
        self.id = id
        self.title = title
        self.usedFraction = usedFraction
        self.resetsAt = resetsAt
    }

    /// Counts must use the same unit and window. Unknown totals stay unknown.
    static func fraction(used: Double, total: Double?) throws -> Double? {
        guard used.isFinite, used >= 0 else { throw UsageSourceError.invalidData }
        guard let total else { return nil }
        guard total.isFinite, total > 0 else { throw UsageSourceError.invalidData }
        let value = used / total
        guard value.isFinite, value <= 1_000 else { throw UsageSourceError.invalidData }
        return value
    }

    var percentage: String {
        guard let usedFraction else { return "—" }
        return usedFraction.formatted(.percent.precision(.fractionLength(0...1)))
    }
}

struct UsageSnapshot: Equatable, Sendable {
    let title: String
    let limits: [UsageLimit]
    /// Time the SOURCE measured the numbers, not time this view was refreshed.
    let measuredAt: Date
    let validFor: TimeInterval

    init(title: String, limits: [UsageLimit], measuredAt: Date, validFor: TimeInterval) throws {
        guard !title.isEmpty, title.count <= 80,
              (1...4).contains(limits.count), Set(limits.map(\.id)).count == limits.count,
              measuredAt.timeIntervalSince1970.isFinite,
              validFor.isFinite, validFor > 0, validFor <= 86_400 else {
            throw UsageSourceError.invalidData
        }
        self.title = title
        self.limits = limits
        self.measuredAt = measuredAt
        self.validFor = validFor
    }

    func isStale(at now: Date) -> Bool { now.timeIntervalSince(measuredAt) >= validFor }
}
