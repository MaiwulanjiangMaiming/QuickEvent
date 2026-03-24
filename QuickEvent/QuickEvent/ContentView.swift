//
//  ContentView.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @FocusState private var isInputFocused: Bool
    @AppStorage("enableLiquidGlass") private var enableLiquidGlass: Bool = true
    
    var body: some View {
        ZStack {
            if enableLiquidGlass {
                LiquidGlassBackground()
            }
            
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title)
                        .foregroundStyle(.blue)
                    Text("QuickEvent")
                        .font(.headline)
                    Spacer()
                    Button(action: { viewModel.clearAll() }) {
                        Image(systemName: "trash")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .padding(4)
                    }
                    .buttonStyle(.borderless)
                    .contentShape(Rectangle())
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        TextField("Tomorrow 3 PM meeting, 1 hour", text: $viewModel.inputText)
                            .textFieldStyle(.roundedBorder)
                            .focused($isInputFocused)
                            .onSubmit {
                                viewModel.parseInput()
                            }
                        
                        VoiceInputButton(isRecording: $viewModel.isVoiceRecording) { text in
                            viewModel.inputText = text
                            viewModel.parseInput()
                        }
                    }
                    
                    HStack {
                        Button("Parse") {
                            viewModel.parseInput()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.inputText.isEmpty)
                        .keyboardShortcut(.return, modifiers: [])
                        
                        Spacer()
                        
                        if viewModel.isProcessing {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                    
                    Text("Supports: English · 中文 · العربية · Français · Русский · Español")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                if viewModel.showPreview {
                    Divider()
                    
                    if let event = viewModel.parsedEvent {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "calendar")
                                    .font(.title3)
                                    .foregroundStyle(.blue)
                                Text(event.title)
                                    .font(.headline)
                            }
                            
                            HStack {
                                Image(systemName: "clock")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 20)
                                Text(event.startDate.formatted(date: .long, time: .shortened))
                                    .font(.subheadline)
                            }
                            
                            if let location = event.location, !location.isEmpty {
                                HStack {
                                    Image(systemName: "location")
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 20)
                                    Text(location)
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        
                        CalendarSelectorView(viewModel: viewModel)
                        
                        HStack(spacing: 12) {
                            Button("Export ICS") {
                                viewModel.exportICS()
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Add to Calendar") {
                                viewModel.addToCalendar()
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(!viewModel.hasCalendarAccess)
                        }
                    } else if let error = viewModel.parseError {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                
                Spacer()
                
                HStack {
                    Text("⌘⇧V: Voice | Enter: Parse")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Spacer()
                    SettingsButton()
                }
            }
            .padding()
        }
        .frame(minWidth: 380, minHeight: 400)
        .onAppear {
            NSApp.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isInputFocused = true
            }
        }
    }
}

struct CalendarSelectorView: View {
    @ObservedObject var viewModel: EventViewModel
    @State private var hoveredCalendar: EKCalendar?
    @State private var showReadOnlyWarning: Bool = false
    @State private var pendingCalendar: EKCalendar?
    
    private let eventKitManager = EventKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar:")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Menu {
                if !eventKitManager.writableCalendars.isEmpty {
                    Section("Writable Calendars") {
                        ForEach(eventKitManager.writableCalendars, id: \.calendarIdentifier) { calendar in
                            Button(action: { selectCalendar(calendar) }) {
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                    if viewModel.selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !eventKitManager.readonlyCalendars.isEmpty {
                    Section("Read-Only Calendars") {
                        ForEach(eventKitManager.readonlyCalendars, id: \.calendarIdentifier) { calendar in
                            Button(action: { selectCalendar(calendar) }) {
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if viewModel.selectedCalendar?.calendarIdentifier == calendar.calendarIdentifier {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let calendar = viewModel.selectedCalendar {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor))
                            .frame(width: 12, height: 12)
                        Text(calendar.title)
                            .foregroundStyle(.primary)
                        if eventKitManager.isCalendarReadOnly(calendar) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Select Calendar")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .alert("Read-Only Calendar", isPresented: $showReadOnlyWarning) {
            Button("Cancel", role: .cancel) {
                pendingCalendar = nil
            }
            Button("Continue Anyway") {
                if let calendar = pendingCalendar {
                    viewModel.selectedCalendar = calendar
                }
                pendingCalendar = nil
            }
        } message: {
            Text("This calendar is read-only. Events may not be saved. Continue anyway?")
        }
    }
    
    private func selectCalendar(_ calendar: EKCalendar) {
        if eventKitManager.isCalendarReadOnly(calendar) {
            pendingCalendar = calendar
            showReadOnlyWarning = true
        } else {
            viewModel.selectedCalendar = calendar
        }
    }
}

struct SettingsButton: View {
    var body: some View {
        Button(action: openSettingsFallback) {
            Image(systemName: "gearshape")
                .font(.title3)
                .foregroundStyle(.secondary)
                .padding(4)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
    }
    
    private func openSettingsFallback() {
        NotificationCenter.default.post(name: Notification.Name("openSettings"), object: nil)
    }
}
