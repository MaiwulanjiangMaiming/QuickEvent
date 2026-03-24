//
//  SettingsView.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import SwiftUI
import EventKit

struct SettingsView: View {
    private enum SettingsTab: String, CaseIterable, Identifiable {
        case general
        case calendar
        case about
        
        var id: String { rawValue }
        
        var title: String {
            switch self {
            case .general: return "General"
            case .calendar: return "Calendar"
            case .about: return "About"
            }
        }
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .calendar: return "calendar"
            case .about: return "sparkles"
            }
        }
    }
    
    private struct TabItemButtonStyle: ButtonStyle {
        let isHovered: Bool
        let isSelected: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(backgroundStyle(configuration.isPressed))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.white.opacity(borderOpacity(configuration.isPressed)), lineWidth: 1)
                )
                .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
                .opacity(configuration.isPressed ? 0.92 : 1.0)
                .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
        }
        
        private func backgroundStyle(_ isPressed: Bool) -> AnyShapeStyle {
            if isPressed {
                return AnyShapeStyle(.regularMaterial)
            }
            if isHovered || isSelected {
                return AnyShapeStyle(.thinMaterial)
            }
            return AnyShapeStyle(Color.clear)
        }
        
        private func borderOpacity(_ isPressed: Bool) -> Double {
            if isPressed {
                return 0.28
            }
            if isHovered {
                return 0.2
            }
            if isSelected {
                return 0.16
            }
            return 0.08
        }
    }
    
    @AppStorage("defaultDuration") private var defaultDuration: Double = 60
    @AppStorage("defaultReminder") private var defaultReminder: Double = 15
    @AppStorage("launchAtLogin") private var launchAtLogin: Bool = false
    @AppStorage("enableLiquidGlass") private var enableLiquidGlass: Bool = true
    @AppStorage("windowFloating") private var windowFloating: Bool = false
    @AppStorage("windowCentered") private var windowCentered: Bool = true
    
    @StateObject private var eventKitManager = EventKitManager.shared
    @State private var selectedTab: SettingsTab = .general
    @State private var hoveredTab: SettingsTab?
    @State private var hoveredCalendar: EKCalendar?
    @State private var showReadOnlyWarning: Bool = false
    @State private var pendingCalendar: EKCalendar?
    
    var body: some View {
        ZStack {
            Color(nsColor: .windowBackgroundColor)
                .opacity(enableLiquidGlass ? 0.72 : 1.0)
            if enableLiquidGlass {
                LiquidGlassBackground()
                    .opacity(0.9)
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.16),
                        Color.blue.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .blendMode(.screen)
            }
            VStack(spacing: 12) {
                tabHeader
                Group {
                    switch selectedTab {
                    case .general:
                        generalTab
                    case .calendar:
                        calendarTab
                    case .about:
                        aboutTab
                    }
                }
            }
            .padding(14)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(Color.white.opacity(enableLiquidGlass ? 0.2 : 0.08), lineWidth: 1)
                    .padding(14)
            )
        }
        .frame(width: 500, height: 420)
    }
    
    private var tabHeader: some View {
        HStack(spacing: 8) {
            ForEach(SettingsTab.allCases) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 12, weight: .semibold))
                        Text(tab.title)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(TabItemButtonStyle(isHovered: hoveredTab == tab, isSelected: selectedTab == tab))
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .focusable(false)
                .onHover { isHovering in
                    hoveredTab = isHovering ? tab : (hoveredTab == tab ? nil : hoveredTab)
                }
            }
        }
        .padding(6)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var generalTab: some View {
        Form {
            Section("Window") {
                HStack {
                    Text("Always on Top")
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { windowFloating },
                        set: { newValue in
                            windowFloating = newValue
                            NotificationCenter.default.post(name: .windowSettingsChanged, object: nil)
                        }
                    ))
                }
                HStack {
                    Text("Center Window")
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { windowCentered },
                        set: { newValue in
                            windowCentered = newValue
                            NotificationCenter.default.post(name: .windowSettingsChanged, object: nil)
                        }
                    ))
                }
            }
            
            Section("Appearance") {
                Toggle("Liquid Glass Effect", isOn: $enableLiquidGlass)
            }
            
            Section("Event Defaults") {
                HStack {
                    Text("Default Duration")
                    Spacer()
                    TextField("", value: $defaultDuration, format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                    Text("minutes")
                }
                
                HStack {
                    Text("Default Reminder")
                    Spacer()
                    TextField("", value: $defaultReminder, format: .number)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                    Text("minutes before")
                }
            }
            
            Section("System") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }
    
    private var calendarTab: some View {
        Form {
            Section("Calendar Access") {
                HStack {
                    Image(systemName: eventKitManager.hasAccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(eventKitManager.hasAccess ? .green : .red)
                    Text(eventKitManager.hasAccess ? "Access Granted" : "Access Required")
                    Spacer()
                    if !eventKitManager.hasAccess {
                        Button("Grant Access") {
                            eventKitManager.requestAccess()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            
            if eventKitManager.hasAccess {
                if !eventKitManager.writableCalendars.isEmpty {
                    Section("Writable Calendars") {
                        ForEach(eventKitManager.writableCalendars, id: \.calendarIdentifier) { calendar in
                            CalendarRowView(
                                calendar: calendar,
                                isSelected: eventKitManager.selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier,
                                isHovered: hoveredCalendar?.calendarIdentifier == calendar.calendarIdentifier,
                                isReadOnly: false
                            ) {
                                eventKitManager.selectedCalendar = calendar
                            }
                            .onHover { isHovering in
                                hoveredCalendar = isHovering ? calendar : nil
                            }
                        }
                    }
                }
                
                if !eventKitManager.readonlyCalendars.isEmpty {
                    Section("Read-Only Calendars") {
                        ForEach(eventKitManager.readonlyCalendars, id: \.calendarIdentifier) { calendar in
                            CalendarRowView(
                                calendar: calendar,
                                isSelected: eventKitManager.selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier,
                                isHovered: hoveredCalendar?.calendarIdentifier == calendar.calendarIdentifier,
                                isReadOnly: true
                            ) {
                                pendingCalendar = calendar
                                showReadOnlyWarning = true
                            }
                            .onHover { isHovering in
                                hoveredCalendar = isHovering ? calendar : nil
                            }
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .alert("Read-Only Calendar", isPresented: $showReadOnlyWarning) {
            Button("Cancel", role: .cancel) {
                pendingCalendar = nil
            }
            Button("Continue Anyway") {
                if let calendar = pendingCalendar {
                    eventKitManager.selectedCalendar = calendar
                }
                pendingCalendar = nil
            }
        } message: {
            Text("This calendar is read-only. Events may not be saved. Continue anyway?")
        }
    }
    
    private var aboutTab: some View {
        VStack(spacing: 16) {
            VStack(spacing: 10) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(.blue, .cyan)
                Text("QuickEvent")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Version 1.0.0")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            
            Link(destination: URL(string: "https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper")!) {
                HStack {
                    Image(systemName: "link")
                    Text("Open Repository")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            VStack(spacing: 6) {
                Text("Created by Maiwulanjiang Maiming")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Made with SwiftUI for macOS")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.bottom, 4)
        }
        .padding(12)
        .background(Color.clear)
    }
}

struct CalendarRowView: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let isHovered: Bool
    let isReadOnly: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(isHovered ? Color(cgColor: calendar.cgColor) : Color(cgColor: calendar.cgColor).opacity(0.8))
                .frame(width: isHovered ? 14 : 12, height: isHovered ? 14 : 12)
                .animation(.easeInOut(duration: 0.15), value: isHovered)
            
            Text(calendar.title)
            
            if isReadOnly {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(cgColor: calendar.cgColor).opacity(0.15) : Color.clear)
        )
    }
}

struct LiquidGlassBackground: View {
    var body: some View {
        ZStack {
            VisualEffectBlur(material: .underWindowBackground, blendingMode: .behindWindow)
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow)
                .opacity(0.45)
        }
        .ignoresSafeArea()
    }
}

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        view.isEmphasized = true
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.isEmphasized = true
    }
}
