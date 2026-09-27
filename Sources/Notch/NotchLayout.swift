import Foundation

enum NotchLayout {
    static let curlRadius: CGFloat = Design.px(103)
    static let cornerRadius: CGFloat = Design.px(78.8)
    static let cardSize = CGSize(width: 280, height: 214)
    static let depth: CGFloat = 80
    static let cell: CGFloat = 76
    static func length(count: Int) -> CGFloat { CGFloat(max(count, 1)) * cell + 66 }
}

/// All hit testing uses the same rectangles as rendering.
struct NotchMetrics {
    let edge: NotchEdge
    let count: Int
    let scale: CGFloat
    var barLength: CGFloat { NotchLayout.length(count: count) * scale }
    var barDepth: CGFloat { NotchLayout.depth * scale }
    var size: CGSize {
        NotchPlacement.panelSize(edge: edge, length: max(barLength + 32, 320),
            depth: barDepth + 16 + (edge.isVertical ? NotchLayout.cardSize.width : NotchLayout.cardSize.height))
    }
    var placement: NotchPlacement { NotchPlacement(edge: edge, panelSize: size) }
    var start: CGFloat { (placement.panelLength - barLength) / 2 }
    func bar(expanded: Bool) -> CGRect {
        placement.rect(along: expanded ? start : (placement.panelLength - 52) / 2,
                       across: 0, length: expanded ? barLength : 52,
                       depth: expanded ? barDepth : 10)
    }
    func cellRect(_ index: Int) -> CGRect {
        placement.rect(along: start + (18 + CGFloat(index) * NotchLayout.cell) * scale,
                       across: 4 * scale, length: NotchLayout.cell * scale, depth: 72 * scale)
    }
    var settingsRect: CGRect {
        placement.rect(along: start + barLength - 42 * scale, across: 16 * scale,
                       length: 26 * scale, depth: 40 * scale)
    }
    var card: CGRect {
        placement.rect(along: (placement.panelLength - (edge.isVertical ? NotchLayout.cardSize.height : NotchLayout.cardSize.width)) / 2,
                       across: barDepth + 12,
                       length: edge.isVertical ? NotchLayout.cardSize.height : NotchLayout.cardSize.width,
                       depth: edge.isVertical ? NotchLayout.cardSize.width : NotchLayout.cardSize.height)
    }
}
