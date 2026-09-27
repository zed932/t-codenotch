import XCTest
@testable import Codenotch

final class UsageModelTests: XCTestCase {
    func testFractionKeepsUnknownTotalUnknown() throws {
        XCTAssertNil(try UsageLimit.fraction(used: 10, total: nil))
        XCTAssertEqual(try UsageLimit.fraction(used: 25, total: 100), 0.25)
    }

    func testInvalidValuesAreRejected() {
        XCTAssertThrowsError(try UsageLimit.fraction(used: -1, total: 10))
        XCTAssertThrowsError(try UsageLimit.fraction(used: 1, total: 0))
        XCTAssertThrowsError(try UsageLimit(id: "", title: "x", usedFraction: 0.1))
        XCTAssertThrowsError(try UsageLimit(id: "a", title: "x", usedFraction: .nan))
    }

    func testSnapshotRequiresOneToFourUniqueLimits() throws {
        let limit = try UsageLimit(id: "a", title: "A", usedFraction: 0.5)
        XCTAssertThrowsError(try UsageSnapshot(title: "T", limits: [], measuredAt: Date(), validFor: 60))
        XCTAssertThrowsError(try UsageSnapshot(title: "T", limits: [limit, limit], measuredAt: Date(), validFor: 60))
    }

    func testStaleness() throws {
        let measured = Date(timeIntervalSince1970: 1_000)
        let snapshot = try UsageSnapshot(title: "T", limits: [UsageLimit(id: "a", title: "A", usedFraction: nil)],
                                         measuredAt: measured, validFor: 60)
        XCTAssertFalse(snapshot.isStale(at: measured.addingTimeInterval(59)))
        XCTAssertTrue(snapshot.isStale(at: measured.addingTimeInterval(60)))
    }

    func testMissingFractionIsNotZeroPercent() throws {
        XCTAssertEqual(try UsageLimit(id: "a", title: "A", usedFraction: nil).percentage, "—")
    }
}

@MainActor
final class UsageStoreTests: XCTestCase {
    private struct FailingSource: UsageSource {
        func fetchSnapshot() async throws -> UsageSnapshot { throw UsageSourceError.unavailable }
    }

    private struct FutureSource: UsageSource {
        func fetchSnapshot() async throws -> UsageSnapshot {
            try UsageSnapshot(title: "T", limits: [UsageLimit(id: "a", title: "A", usedFraction: 0.1)],
                              measuredAt: Date().addingTimeInterval(3_600), validFor: 60)
        }
    }

    func testDefaultSourceIsNotConfigured() async {
        let store = UsageStore()
        await store.refresh()
        XCTAssertEqual(store.status, .notConfigured)
        XCTAssertNil(store.snapshot)
        XCTAssertFalse(store.isDemo)
    }

    func testDemoIsLabelled() async {
        let store = UsageStore(source: DemoUsageSource(), isDemo: true)
        await store.refresh()
        XCTAssertEqual(store.status, .ready)
        XCTAssertEqual(store.message(at: Date()), "Демонстрационные данные")
    }

    func testReplacingSourceDiscardsDemoReadings() async {
        let store = UsageStore(source: DemoUsageSource(), isDemo: true)
        await store.refresh()
        store.replaceSource(UnconfiguredUsageSource(), isDemo: false)
        XCTAssertNil(store.snapshot)
        XCTAssertFalse(store.isDemo)
    }

    func testFailureKeepsPreviousReadingButMarksStale() async {
        let store = UsageStore(source: DemoUsageSource(), isDemo: true)
        await store.refresh()
        store.replaceSource(FailingSource(), isDemo: false)
        await store.refresh()
        XCTAssertEqual(store.status, .failed)
        XCTAssertTrue(store.isStale(at: Date()))
    }

    func testFutureTimestampIsRejected() async {
        let store = UsageStore(source: FutureSource())
        await store.refresh()
        XCTAssertEqual(store.status, .failed)
        XCTAssertNil(store.snapshot)
    }
}
