//
//  EventKitManager.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import Foundation
import EventKit
import Cocoa

class EventKitManager: ObservableObject {
    static let shared = EventKitManager()
    
    private let eventStore = EKEventStore()
    
    @Published var hasAccess: Bool = false
    @Published var calendars: [EKCalendar] = []
    @Published var writableCalendars: [EKCalendar] = []
    @Published var readonlyCalendars: [EKCalendar] = []
    @Published var selectedCalendar: EKCalendar?
    @Published var accessError: String?
    
    private init() {}
    
    var allCalendars: [EKCalendar] {
        calendars
    }
    
    func requestAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.handleAccessResult(granted: granted, error: error)
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, error in
                DispatchQueue.main.async {
                    self?.handleAccessResult(granted: granted, error: error)
                }
            }
        }
    }
    
    private func handleAccessResult(granted: Bool, error: Error?) {
        hasAccess = granted
        if granted {
            loadCalendars()
        }
        if let error = error {
            accessError = error.localizedDescription
            print("EventKit access error: \(error.localizedDescription)")
        }
    }
    
    private func loadCalendars() {
        calendars = eventStore.calendars(for: .event)
        writableCalendars = calendars.filter { $0.allowsContentModifications }
        readonlyCalendars = calendars.filter { !$0.allowsContentModifications }
        selectedCalendar = writableCalendars.first { $0.type == .local } ?? writableCalendars.first ?? calendars.first
    }
    
    func isCalendarReadOnly(_ calendar: EKCalendar) -> Bool {
        return !calendar.allowsContentModifications
    }
    
    func addEvent(_ parsedEvent: ParsedEvent, to calendar: EKCalendar? = nil) throws {
        guard hasAccess else {
            throw EventKitError.noAccess
        }
        
        let targetCalendar = calendar ?? selectedCalendar
        
        guard let targetCalendar = targetCalendar else {
            throw EventKitError.noCalendar
        }
        
        let event = EKEvent(eventStore: eventStore)
        event.calendar = targetCalendar
        event.title = parsedEvent.title
        event.startDate = parsedEvent.startDate
        event.endDate = parsedEvent.endDate ?? parsedEvent.startDate.addingTimeInterval(3600)
        
        if let location = parsedEvent.location {
            event.location = location
        }
        
        if let notes = parsedEvent.description {
            event.notes = notes
        }
        
        if let reminder = parsedEvent.reminder {
            let alarm = EKAlarm(relativeOffset: TimeInterval(-reminder * 60))
            event.addAlarm(alarm)
        }
        
        do {
            try eventStore.save(event, span: .thisEvent)
        } catch {
            throw EventKitError.saveFailed(error.localizedDescription)
        }
    }
    
    func openCalendarApp() {
        if let url = URL(string: "ical://") {
            NSWorkspace.shared.open(url)
        }
    }
    
    func openSystemPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }
}

enum EventKitError: LocalizedError {
    case noAccess
    case noCalendar
    case saveFailed(String)
    case readOnlyCalendar
    
    var errorDescription: String? {
        switch self {
        case .noAccess:
            return "No calendar access. Please grant permission in System Settings."
        case .noCalendar:
            return "No calendar selected"
        case .saveFailed(let message):
            return "Failed to save event: \(message)"
        case .readOnlyCalendar:
            return "This calendar is read-only. Changes may not be saved."
        }
    }
}
