import Foundation

struct AttendeeParser {
    static let chineseAttendeesRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "跟([\\w\\s,、]+?)(?=\\s*(?:在|\\d|$))")
    }()

    static let englishAttendeesRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "with\\s+([\\w\\s,]+?)(?=\\s+(?:at|in|\\d|$))", options: .caseInsensitive)
    }()

    static let withRemovalRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(?i)with\\s+")
    }()

    func extractAttendees(from input: String) -> [String]? {
        let fullRange = NSRange(input.startIndex..., in: input)

        if let match = Self.chineseAttendeesRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let attendeesStr = String(input[swiftRange])
                    .replacingOccurrences(of: "跟", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let attendees = attendeesStr
                    .split(separator: ",")
                    .flatMap { $0.split(separator: "、") }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                return attendees.isEmpty ? nil : attendees
            }
        }

        if let match = Self.englishAttendeesRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matchedStr = String(input[swiftRange])
                let removalRange = NSRange(matchedStr.startIndex..., in: matchedStr)
                let attendeesStr = Self.withRemovalRegex.stringByReplacingMatches(
                    in: matchedStr,
                    options: [],
                    range: removalRange,
                    withTemplate: ""
                ).trimmingCharacters(in: .whitespacesAndNewlines)

                let attendees = attendeesStr
                    .split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                return attendees.isEmpty ? nil : attendees
            }
        }

        return nil
    }
}
