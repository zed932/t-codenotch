import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let preferences = Preferences()
    private let store = UsageStore()
    private var controllers: [NotchWindowController] = []
    private var settingsWindow: NSWindow?
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    static let refreshInterval: TimeInterval = 60

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.mainMenu = makeMainMenu()
        rebuildNotches()

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildNotches() }
            .store(in: &cancellables)
        preferences.$allDisplays.dropFirst().removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.rebuildNotches() }
            .store(in: &cancellables)
        preferences.$demo.dropFirst().removeDuplicates()
            .sink { [weak self] demo in self?.switchSource(demo: demo) }
            .store(in: &cancellables)

        refreshTimer = Timer.scheduledTimer(withTimeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        refresh()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showSettings()
        return true
    }

    private func switchSource(demo: Bool) {
        store.replaceSource(UsageSourceFactory.makeSource(demo: demo), isDemo: demo)
        refresh()
    }

    @objc private func refresh() {
        Task { await store.refresh() }
    }

    private func rebuildNotches() {
        controllers.forEach { $0.close() }
        let screens = preferences.allDisplays ? NSScreen.screens : [NSScreen.main].compactMap { $0 }
        controllers = screens.map { screen in
            NotchWindowController(screen: screen, store: store, preferences: preferences,
                                  onSettings: { [weak self] in self?.showSettings() },
                                  menu: { [weak self] in self?.makeContextMenu() })
        }
    }

    @objc private func showSettings() {
        if settingsWindow == nil {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: SettingsView(preferences: preferences, store: store)))
            window.title = "Настройки Codenotch"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate()
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(item("Обновить", #selector(refresh)))
        menu.addItem(item("Настройки…", #selector(showSettings)))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Выйти", action: #selector(NSApplication.terminate(_:)), keyEquivalent: ""))
        return menu
    }

    private func makeMainMenu() -> NSMenu {
        let appMenu = NSMenu()
        appMenu.addItem(item("Настройки…", #selector(showSettings), key: ","))
        appMenu.addItem(item("Обновить", #selector(refresh), key: "r"))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Скрыть Codenotch", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "Выйти из Codenotch", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        let windowMenu = NSMenu(title: "Окно")
        windowMenu.addItem(NSMenuItem(title: "Закрыть", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))

        let main = NSMenu()
        for submenu in [appMenu, windowMenu] {
            let holder = NSMenuItem()
            holder.submenu = submenu
            main.addItem(holder)
        }
        return main
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }
}
