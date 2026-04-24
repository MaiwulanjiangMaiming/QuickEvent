import AppKit
import Carbon.HIToolbox

class HotkeyManager {
    private var eventMonitor: Any?
    private let onHotkey: () -> Void

    init(onHotkey: @escaping () -> Void) {
        self.onHotkey = onHotkey
    }

    func setup() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.modifierFlags.contains(.command) &&
               event.modifierFlags.contains(.shift) &&
               event.keyCode == UInt16(kVK_ANSI_V) {
                DispatchQueue.main.async {
                    self?.onHotkey()
                }
            }
        }
    }

    func teardown() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
