//
//  ICSGenerator.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import Foundation

class ICSGenerator {
    static let shared = ICSGenerator()
    
    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
    
    private let uidFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        return formatter
    }()
    
    func generateICS(for event: ParsedEvent) throws -> String {
        var ics = "BEGIN:VCALENDAR\n"
        ics += "VERSION:2.0\n"
        ics += "PRODID:-//QuickEvent//macOS//EN\n"
        ics += "CALSCALE:GREGORIAN\n"
        ics += "METHOD:PUBLISH\n"
        ics += generateEvent(event)
        ics += "END:VCALENDAR\n"
        
        return ics
    }
    
    private func generateEvent(_ event: ParsedEvent) -> String {
        var eventStr = "BEGIN:VEVENT\n"
        
        let uid = "quickevent-\(uidFormatter.string(from: Date()))-\(event.id.uuidString)"
        eventStr += "UID:\(uid)\n"
        
        eventStr += "DTSTAMP:\(dateFormatter.string(from: Date()))\n"
        
        eventStr += "DTSTART:\(dateFormatter.string(from: event.startDate))\n"
        
        if let endDate = event.endDate {
            eventStr += "DTEND:\(dateFormatter.string(from: endDate))\n"
        }
        
        eventStr += "SUMMARY:\(escapeText(event.title))\n"
        
        if let location = event.location {
            eventStr += "LOCATION:\(escapeText(location))\n"
        }
        
        if let description = event.description {
            eventStr += "DESCRIPTION:\(escapeText(description))\n"
        }
        
        if let attendees = event.attendees {
            for attendee in attendees {
                eventStr += "ATTENDEE;CN=\(escapeText(attendee)):mailto:\(attendee.lowercased().replacingOccurrences(of: " ", with: "."))@example.com\n"
            }
        }
        
        if let reminder = event.reminder {
            eventStr += "BEGIN:VALARM\n"
            eventStr += "ACTION:DISPLAY\n"
            eventStr += "DESCRIPTION:\(escapeText(event.title))\n"
            eventStr += "TRIGGER:-PT\(reminder)M\n"
            eventStr += "END:VALARM\n"
        }
        
        eventStr += "END:VEVENT\n"
        
        return eventStr
    }
    
    private func escapeText(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: ",", with: "\\,")
            .replacingOccurrences(of: ";", with: "\\;")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
    
    func saveICS(_ content: String, to url: URL) throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    func exportEvent(_ event: ParsedEvent) throws -> URL {
        let icsContent = try generateICS(for: event)
        
        let fileName = "\(event.title.replacingOccurrences(of: " ", with: "_"))_\(uidFormatter.string(from: event.startDate)).ics"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        try saveICS(icsContent, to: fileURL)
        
        return fileURL
    }
}
