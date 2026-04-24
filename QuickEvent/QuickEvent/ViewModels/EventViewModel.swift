import Foundation
import SwiftUI
import Combine
import EventKit

@MainActor
class EventViewModel: ObservableObject {
    @Published var inputText: String = ""
    @Published var parsedEvent: ParsedEvent?
    @Published var showPreview: Bool = false
    @Published var parseError: String?
    @Published var isProcessing: Bool = false

    let appState: AppState
    private let parser: EventParsing
    private let calendarManager: CalendarManaging
    private let icsExporter: ICSExportService

    var hasCalendarAccess: Bool {
        calendarManager.hasAccess
    }

    var selectedCalendar: EKCalendar? {
        guard let id = appState.selectedCalendarID else {
            return calendarManager.writableCalendars.first
        }
        return calendarManager.writableCalendars.first { $0.calendarIdentifier == id }
            ?? calendarManager.readonlyCalendars.first { $0.calendarIdentifier == id }
    }

    init(
        appState: AppState = .shared,
        parser: EventParsing = NaturalLanguageParser(),
        calendarManager: CalendarManaging = EventKitManager.shared,
        icsExporter: ICSExportService = ICSExportService()
    ) {
        self.appState = appState
        self.parser = parser
        self.calendarManager = calendarManager
        self.icsExporter = icsExporter
    }

    func toggleVoiceInput() {
        appState.toggleVoiceInput()
    }

    func parseInput() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            parseError = "Please enter event details"
            showPreview = true
            parsedEvent = nil
            return
        }

        isProcessing = true
        parseError = nil

        Task {
            do {
                let event = try await parser.parse(inputText)

                await MainActor.run {
                    parsedEvent = event
                    showPreview = true
                    parseError = nil
                    isProcessing = false
                }
            } catch {
                await MainActor.run {
                    parseError = error.localizedDescription
                    showPreview = true
                    parsedEvent = nil
                    isProcessing = false
                }
            }
        }
    }

    func exportICS() {
        guard let event = parsedEvent else { return }

        if let result = icsExporter.exportWithSavePanel(event) {
            if result.hasPrefix("Failed") {
                parseError = result
            } else {
                appState.showSuccess(result)
            }
        }
    }

    func addToCalendar() {
        guard let event = parsedEvent else { return }

        Task {
            do {
                try calendarManager.addEvent(event, to: selectedCalendar)
                appState.showSuccess("Event added to calendar")
                calendarManager.openCalendarApp()
            } catch {
                parseError = error.localizedDescription
            }
        }
    }

    func clearAll() {
        inputText = ""
        parsedEvent = nil
        showPreview = false
        parseError = nil
    }
}
