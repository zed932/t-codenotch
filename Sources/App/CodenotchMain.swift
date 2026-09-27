import AppKit

@main
enum CodenotchMain {
    /// `NSApplication.delegate` is weak, so the delegate is owned here.
    @MainActor private static var delegate: AppDelegate?

    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        self.delegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        app.run()
    }
}
