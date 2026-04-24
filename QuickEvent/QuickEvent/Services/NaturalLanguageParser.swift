import Foundation

class NaturalLanguageParser: EventParsing {
    private let normalizer = InputNormalizer()
    private let dateParser = DateParser()
    private let timeParser = TimeParser()
    private let durationParser = DurationParser()
    private let locationParser = LocationParser()
    private let attendeeParser = AttendeeParser()
    private let reminderParser = ReminderParser()
    private let titleExtractor = TitleExtractor()

    func parse(_ input: String) async throws -> ParsedEvent {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw ParseError.emptyInput }

        let normalizedInput = normalizer.normalize(trimmed)

        let title = titleExtractor.extractTitle(from: normalizedInput, original: trimmed)
        guard !title.isEmpty else { throw ParseError.missingTitle }

        let startDate: Date
        if let parsedDate = dateParser.parseDate(from: normalizedInput, originalInput: trimmed) {
            startDate = parsedDate
        } else {
            startDate = Date()
        }

        var hasExplicitTime = false
        var finalStartDate = startDate
        if let timeResult = timeParser.parseTime(from: normalizedInput, originalInput: trimmed) {
            let cal = Calendar.current
            var components = cal.dateComponents([.year, .month, .day], from: startDate)
            components.hour = timeResult.hour
            components.minute = timeResult.minute
            if let newDate = cal.date(from: components) {
                finalStartDate = newDate
                hasExplicitTime = true
            }
        }

        if !hasExplicitTime && Calendar.current.isDateInToday(finalStartDate) {
            let now = Date()
            let nextHour = Calendar.current.date(byAdding: .hour, value: 1, to: now) ?? now
            var components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: nextHour)
            components.minute = 0
            if let newDate = Calendar.current.date(from: components) {
                finalStartDate = newDate
            }
        }

        let duration = durationParser.parseDuration(from: normalizedInput) ?? 3600
        let endDate = finalStartDate.addingTimeInterval(duration)

        let location = locationParser.extractLocation(from: normalizedInput)
        let description = extractDescription(from: normalizedInput)
        let attendees = attendeeParser.extractAttendees(from: normalizedInput)
        let reminder = reminderParser.extractReminder(from: normalizedInput)

        return ParsedEvent(
            title: title,
            startDate: finalStartDate,
            endDate: endDate,
            location: location,
            description: description,
            attendees: attendees,
            reminder: reminder
        )
    }

    private func extractDescription(from input: String) -> String? {
        if let match = input.range(of: "备注\\s*[:：]?\\s*([^\\n]+)", options: .regularExpression) {
            return String(input[match])
                .replacingOccurrences(of: "备注\\s*[:：]?\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let match = input.range(of: "note\\s*:\\s*([^\\n]+)", options: [.regularExpression, .caseInsensitive]) {
            return String(input[match])
                .replacingOccurrences(of: "(?i)note\\s*:\\s*", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}
