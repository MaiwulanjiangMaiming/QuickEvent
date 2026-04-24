import SwiftUI

@MainActor
class WindowManager: NSObject, NSWindowDelegate {
    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private let appState: AppState

    var mainWindowRef: NSWindow? { mainWindow }

    init(appState: AppState) {
        self.appState = appState
        super.init()
    }

    func showMainWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if mainWindow == nil {
            let contentView = ContentView()
            let hostingView = NSHostingView(rootView: contentView)

            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 420, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "QuickEvent"
            window.contentView = hostingView
            window.isReleasedWhenClosed = false
            window.hidesOnDeactivate = false
            window.acceptsMouseMovedEvents = true
            window.delegate = self

            mainWindow = window
            applyWindowSettings(window)
        }

        mainWindow?.makeKeyAndOrderFront(nil)
    }

    func showSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)

        if let existingWindow = settingsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            return
        }

        let contentView = SettingsView()
        let hostingView = NSHostingView(rootView: contentView)

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 420),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.hidesOnDeactivate = false
        window.delegate = self
        window.center()

        settingsWindow = window
        window.makeKeyAndOrderFront(nil)
    }

    func applyWindowSettings(_ window: NSWindow) {
        window.level = appState.windowFloating ? .floating : .normal
        if appState.windowCentered {
            window.center()
        }
    }

    func windowWillClose(_ notification: Notification) {
        if let window = notification.object as? NSWindow {
            if window == settingsWindow {
                settingsWindow = nil
            }
        }
    }
}
