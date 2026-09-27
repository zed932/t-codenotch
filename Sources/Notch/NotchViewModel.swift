import SwiftUI

@MainActor
final class NotchViewModel: ObservableObject {
    @Published var expanded = false
    @Published var hoveredIndex: Int?
    @Published var edge: NotchEdge = .right
    @Published var scale: CGFloat = 1
    @Published var count = 1
    var onSettings: (() -> Void)?
    var metrics: NotchMetrics { NotchMetrics(edge: edge, count: count, scale: scale) }
}
