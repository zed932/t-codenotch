import AppKit
import Combine
import SwiftUI

/// One notch on one display. Hover is polled from the pointer position rather
/// than tracked with `NSTrackingArea`, because the panel never becomes key and
/// most of it is a pass-through hole reserved for the card.
@MainActor
final class NotchWindowController {
    private let screen: NSScreen
    private let preferences: Preferences
    private let model = NotchViewModel()
    private let panel: NotchPanel
    private let hosting: NotchHostingView<NotchRootView>
    private var hoverTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    /// Keeps the card open while the pointer crosses the gap between bar and card.
    private static let cardSlop: CGFloat = 16

    init(screen: NSScreen, store: UsageStore, preferences: Preferences,
         onSettings: @escaping () -> Void, menu: @escaping () -> NSMenu?) {
        self.screen = screen
        self.preferences = preferences
        model.onSettings = onSettings
        model.edge = preferences.edge
        model.scale = preferences.scale
        model.expanded = preferences.alwaysExpanded

        panel = NotchPanel(contentRect: .zero)
        hosting = NotchHostingView(rootView: NotchRootView(model: model, store: store))
        let container = NotchContainerView()
        hosting.autoresizingMask = [.width, .height]
        container.addSubview(hosting)
        panel.contentView = container
        panel.contextMenuProvider = menu

        preferences.$edge.dropFirst().sink { [weak self] in self?.model.edge = $0; self?.scheduleLayout() }
            .store(in: &cancellables)
        preferences.$scale.dropFirst().sink { [weak self] in self?.model.scale = $0; self?.scheduleLayout() }
            .store(in: &cancellables)
        preferences.$alwaysExpanded.dropFirst().sink { [weak self] _ in self?.scheduleLayout() }
            .store(in: &cancellables)
        store.$snapshot.sink { [weak self] in
            self?.model.count = max($0?.limits.count ?? 0, 1)
            self?.scheduleLayout()
        }.store(in: &cancellables)

        layout()
        panel.orderFrontRegardless()
        hoverTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.trackPointer() }
        }
    }

    func close() {
        hoverTimer?.invalidate()
        cancellables.removeAll()
        panel.orderOut(nil)
    }

    /// `@Published` delivers before the property changes; lay out afterwards.
    private func scheduleLayout() {
        DispatchQueue.main.async { [weak self] in self?.layout() }
    }

    private func layout() {
        let size = model.metrics.size
        let area = screen.frame
        let origin: CGPoint
        switch model.edge {
        case .right: origin = CGPoint(x: area.maxX - size.width, y: area.midY - size.height / 2)
        case .left: origin = CGPoint(x: area.minX, y: area.midY - size.height / 2)
        case .top: origin = CGPoint(x: area.midX - size.width / 2, y: area.maxY - size.height)
        case .bottom: origin = CGPoint(x: area.midX - size.width / 2, y: area.minY)
        }
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        trackPointer()
    }

    private func trackPointer() {
        let mouse = NSEvent.mouseLocation
        let frame = panel.frame
        // Panel content is flipped: top-left origin.
        let point = CGPoint(x: mouse.x - frame.minX, y: frame.maxY - mouse.y)
        let metrics = model.metrics

        let bar = metrics.bar(expanded: model.expanded)
        let card = metrics.card.insetBy(dx: -Self.cardSlop, dy: -Self.cardSlop)
        let overBar = bar.insetBy(dx: -6, dy: -6).contains(point)
        let overCard = model.hoveredIndex != nil && card.contains(point)
        let expanded = preferences.alwaysExpanded || overBar || overCard

        var index: Int?
        if expanded {
            if let cell = (0..<model.count).first(where: { metrics.cellRect($0).contains(point) }) {
                index = cell
            } else if overBar || overCard {
                index = model.hoveredIndex
            }
        }

        if model.expanded != expanded { model.expanded = expanded }
        if model.hoveredIndex != index { model.hoveredIndex = index }

        var rects = [metrics.bar(expanded: expanded)]
        if index != nil { rects.append(metrics.card) }
        hosting.interactiveRects = rects
    }
}
