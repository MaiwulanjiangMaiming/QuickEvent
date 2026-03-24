//
//  QuickEventApp.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import SwiftUI
import Carbon.HIToolbox
import Speech
import AVFoundation

@main
struct QuickEventApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        EmptyScene()
    }
}

struct EmptyScene: Scene {
    var body: some Scene {
        WindowGroup {
            EmptyView()
                .frame(width: 0, height: 0)
                .onAppear {
                    if let window = NSApplication.shared.windows.first {
                        window.close()
                    }
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 0, height: 0)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var mainWindow: NSWindow?
    private var eventMonitor: Any?
    
    @AppStorage("windowFloating") private var windowFloating: Bool = false
    @AppStorage("windowCentered") private var windowCentered: Bool = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        requestAllPermissions()
        setupStatusBar()
        setupGlobalHotkey()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowSettingsChanged),
            name: .windowSettingsChanged,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openSettingsWindow),
            name: Notification.Name("openSettings"),
            object: nil
        )
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showMainWindow()
        }
    }
    
    private func requestAllPermissions() {
        EventKitManager.shared.requestAccess()
        
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                if status == .notDetermined {
                    print("Speech recognition authorization pending")
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
                        print("Microphone permission denied")
                    }
                }
            }
        case .denied, .restricted:
            print("Microphone permission denied or restricted")
        case .authorized:
            print("Microphone permission already granted")
        @unknown default:
            break
        }
    }
    
    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "calendar.badge.plus", accessibilityDescription: "QuickEvent")
            button.image?.isTemplate = true
            button.action = #selector(statusBarButtonClicked)
            button.target = self
        }
    }
    
    @objc private func statusBarButtonClicked() {
        showMainWindow()
    }
    
    @objc func showMainWindow() {
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
    
    @objc func openSettingsWindow() {
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
    
    @objc func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func applyWindowSettings(_ window: NSWindow) {
        window.level = windowFloating ? .floating : .normal
        if windowCentered {
            window.center()
        }
    }
    
    @objc private func windowSettingsChanged() {
        if let window = mainWindow {
            applyWindowSettings(window)
        }
    }
    
    private func setupGlobalHotkey() {
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && 
               event.modifierFlags.contains(.shift) && 
               event.keyCode == UInt16(kVK_ANSI_V) {
                DispatchQueue.main.async {
                    NSApp.activate(ignoringOtherApps: true)
                    NotificationCenter.default.post(name: .toggleVoiceInput, object: nil)
                }
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
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

extension Notification.Name {
    static let toggleVoiceInput = Notification.Name("toggleVoiceInput")
    static let windowSettingsChanged = Notification.Name("windowSettingsChanged")
}
