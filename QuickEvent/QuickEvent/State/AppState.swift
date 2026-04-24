import Foundation
import SwiftUI
import EventKit

@MainActor
class AppState: ObservableObject {
    static let shared = AppState()

    @AppStorage("windowFloating") var windowFloating: Bool = false
    @AppStorage("windowCentered") var windowCentered: Bool = true

    @AppStorage("enableLiquidGlass") var enableLiquidGlass: Bool = true

    @AppStorage("defaultDuration") var defaultDuration: Double = 60
    @AppStorage("defaultReminder") var defaultReminder: Double = 15

    @AppStorage("launchAtLogin") var launchAtLogin: Bool = false

    @Published var selectedCalendarID: String? = nil

    @Published var isVoiceRecording: Bool = false

    @Published var showSuccessMessage: Bool = false
    @Published var successMessage: String = ""

    @Published var shouldShowMainWindow: Bool = false
    @Published var shouldShowSettingsWindow: Bool = false

    nonisolated init() {}

    func toggleVoiceInput() {
        isVoiceRecording.toggle()
    }

    func showSuccess(_ message: String) {
        successMessage = message
        showSuccessMessage = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
            self?.showSuccessMessage = false
        }
    }

    func triggerMainWindow() {
        shouldShowMainWindow = true
    }

    func triggerSettingsWindow() {
        shouldShowSettingsWindow = true
    }

    func acknowledgeMainWindow() {
        shouldShowMainWindow = false
    }

    func acknowledgeSettingsWindow() {
        shouldShowSettingsWindow = false
    }
}
