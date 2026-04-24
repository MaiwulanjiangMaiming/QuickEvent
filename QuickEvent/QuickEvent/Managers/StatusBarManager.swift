import AppKit

@MainActor
class StatusBarManager {
    private var statusItem: NSStatusItem?
    private let onButtonClick: () -> Void

    init(onButtonClick: @escaping () -> Void) {
        self.onButtonClick = onButtonClick
    }

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: "QuickEvent")
            button.image?.isTemplate = true
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }

    @objc private func statusBarButtonClicked() {
        onButtonClick()
    }
}
