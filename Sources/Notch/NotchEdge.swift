import Foundation

enum NotchEdge: String, CaseIterable, Identifiable {
    case right, left, top, bottom
    var id: String { rawValue }
    var isVertical: Bool { self == .right || self == .left }
    var title: String {
        switch self {
        case .right: return "Справа"
        case .left: return "Слева"
        case .top: return "Сверху"
        case .bottom: return "Снизу"
        }
    }
}
