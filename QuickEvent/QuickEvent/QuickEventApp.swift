import SwiftUI
import Combine

@main
struct QuickEventApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowManager: WindowManager!
    private var statusBarManager: StatusBarManager!
    private var hotkeyManager: HotkeyManager!
    private var permissionManager: PermissionManager!
    private var cancellables = Set<AnyCancellable>()
    private var userDefaultsObserver: NSObjectProtocol?

    let appState = AppState.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        windowManager = WindowManager(appState: appState)
        permissionManager = PermissionManager(calendarManager: EventKitManager.shared)
        statusBarManager = StatusBarManager { [weak self] in
            Task { @MainActor in
                self?.windowManager.showMainWindow()
            }
        }
        hotkeyManager = HotkeyManager { [weak self] in
            NSApp.activate(ignoringOtherApps: true)
            Task { @MainActor in
                self?.appState.toggleVoiceInput()
            }
        }

        permissionManager.requestAllPermissions()
        statusBarManager.setup()
        hotkeyManager.setup()
        setupObservation()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.windowManager.showMainWindow()
        }
    }

    private func setupObservation() {
        userDefaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: UserDefaults.standard,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let window = self.windowManager.mainWindowRef else { return }
                self.windowManager.applyWindowSettings(window)
            }
        }

        appState.$shouldShowSettingsWindow
            .receive(on: DispatchQueue.main)
            .sink { [weak self] show in
                if show {
                    self?.windowManager.showSettingsWindow()
                    self?.appState.acknowledgeSettingsWindow()
                }
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        hotkeyManager.teardown()
        if let observer = userDefaultsObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
