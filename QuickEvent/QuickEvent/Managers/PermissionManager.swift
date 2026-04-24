import Foundation
import Speech
import AVFoundation
import EventKit

@MainActor
class PermissionManager {
    private let calendarManager: CalendarManaging

    init(calendarManager: CalendarManaging) {
        self.calendarManager = calendarManager
    }

    func requestAllPermissions() {
        calendarManager.requestAccess()

        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .notDetermined {
                    AppLogger.permission.info("Speech recognition authorization pending")
                }
            }
        }

        requestMicrophonePermission()
    }

    private func requestMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    if !granted {
                        AppLogger.permission.warning("Microphone permission denied")
                    }
                }
            }
        case .denied, .restricted:
            AppLogger.permission.warning("Microphone permission denied or restricted")
        case .authorized:
            AppLogger.permission.debug("Microphone permission already granted")
        @unknown default:
            break
        }
    }
}
