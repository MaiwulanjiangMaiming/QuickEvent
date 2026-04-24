import SwiftUI
import EventKit

struct ContentView: View {
    @StateObject private var viewModel = EventViewModel()
    @ObservedObject var appState: AppState = .shared
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            if appState.enableLiquidGlass {
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

                        VoiceInputButton(isRecording: $appState.isVoiceRecording) { text in
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

                    Text("Supports: English · 中文 · العربية · Français · Русky · Español")
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

                        SharedCalendarPicker(
                            calendars: EventKitManager.shared.writableCalendars + EventKitManager.shared.readonlyCalendars,
                            selectedCalendarID: viewModel.selectedCalendar?.calendarIdentifier,
                            onSelectCalendar: { calendar in
                                viewModel.appState.selectedCalendarID = calendar.calendarIdentifier
                            },
                            isReadOnly: { calendar in
                                EventKitManager.shared.isCalendarReadOnly(calendar)
                            }
                        )

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
                        ErrorBanner(message: error)
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
        AppState.shared.triggerSettingsWindow()
    }
}
