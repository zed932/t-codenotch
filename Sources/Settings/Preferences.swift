import Foundation
import Combine

/// Only appearance preferences persist. No migration from upstream domains.
@MainActor
final class Preferences: ObservableObject {
    @Published var edge: NotchEdge { didSet { defaults.set(edge.rawValue, forKey: "edge") } }
    @Published var scale: Double { didSet { defaults.set(scale, forKey: "scale") } }
    @Published var allDisplays: Bool { didSet { defaults.set(allDisplays, forKey: "allDisplays") } }
    @Published var alwaysExpanded: Bool { didSet { defaults.set(alwaysExpanded, forKey: "alwaysExpanded") } }
    /// Demo mode intentionally resets on every launch.
    @Published var demo = false
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        edge = NotchEdge(rawValue: defaults.string(forKey: "edge") ?? "") ?? .right
        let saved = defaults.double(forKey: "scale")
        scale = saved.isFinite && (0.8...1.25).contains(saved) ? saved : 1
        allDisplays = defaults.bool(forKey: "allDisplays")
        alwaysExpanded = defaults.bool(forKey: "alwaysExpanded")
    }
}
