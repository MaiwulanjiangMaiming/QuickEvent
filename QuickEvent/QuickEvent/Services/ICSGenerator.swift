import Foundation

class ICSGenerator: ICSExporting {
    static let shared = ICSGenerator()

    private let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withTimeZone]
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private let uidFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmss"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter
    }()

    private let crlf = "\r\n"

    private init() {}

    func generateICS(for event: ParsedEvent) throws -> String {
        var lines: [String] = []
        lines.append("BEGIN:VCALENDAR")
        lines.append("VERSION:2.0")
        lines.append("PRODID:-//QuickEvent//macOS//EN")
        lines.append("CALSCALE:GREGORIAN")
        lines.append("METHOD:PUBLISH")
        lines.append(contentsOf: generateEventLines(event))
        lines.append("END:VCALENDAR")

        return lines.map { foldLine($0) }.joined(separator: crlf) + crlf
    }

    private func generateEventLines(_ event: ParsedEvent) -> [String] {
        var lines: [String] = []
        lines.append("BEGIN:VEVENT")

        let uid = "quickevent-\(uidFormatter.string(from: Date()))-\(event.id.uuidString)"
        lines.append("UID:\(uid)")

        lines.append("DTSTAMP:\(dateFormatter.string(from: Date()))")

        lines.append("DTSTART:\(dateFormatter.string(from: event.startDate))")

        if let endDate = event.endDate {
            lines.append("DTEND:\(dateFormatter.string(from: endDate))")
        }

        lines.append("SUMMARY:\(escapeText(event.title))")

        if let location = event.location {
            lines.append("LOCATION:\(escapeText(location))")
        }

        if let description = event.description {
            lines.append("DESCRIPTION:\(escapeText(description))")
        }

        if let attendees = event.attendees {
            for attendee in attendees {
                let escapedName = escapeText(attendee)
                let email = "\(attendee.lowercased().replacingOccurrences(of: " ", with: "."))@quick.event"
                lines.append("ATTENDEE;CN=\(escapedName):mailto:\(email)")
            }
        }

        if let reminder = event.reminder {
            lines.append("BEGIN:VALARM")
            lines.append("ACTION:DISPLAY")
            lines.append("DESCRIPTION:\(escapeText(event.title))")
            lines.append("TRIGGER:-PT\(reminder)M")
            lines.append("END:VALARM")
        }

        lines.append("END:VEVENT")

        return lines
    }

    private func foldLine(_ line: String) -> String {
        let maxOctets = 75
        let utf8 = line.utf8

        if utf8.count <= maxOctets {
            return line
        }

        var result = ""
        var currentLine = line
        var isFirstLine = true

        while currentLine.utf8.count > (isFirstLine ? maxOctets : maxOctets - 1) {
            let limit = isFirstLine ? maxOctets : maxOctets - 1
            var splitIndex = currentLine.startIndex
            var byteCount = 0

            for (i, scalar) in currentLine.unicodeScalars.enumerated() {
                let scalarUTF8Count = scalar.utf8.count
                if byteCount + scalarUTF8Count > limit {
                    break
                }
                byteCount += scalarUTF8Count
                splitIndex = currentLine.index(currentLine.startIndex, offsetBy: i)
            }

            if splitIndex == currentLine.startIndex {
                splitIndex = currentLine.index(after: currentLine.startIndex)
            }

            let chunk = String(currentLine[..<splitIndex])
            currentLine = String(currentLine[splitIndex...])

            if isFirstLine {
                result += chunk
                isFirstLine = false
            } else {
                result += crlf + " " + chunk
            }
        }

        if !currentLine.isEmpty {
            result += crlf + " " + currentLine
        }

        return result
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
