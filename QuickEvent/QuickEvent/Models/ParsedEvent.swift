import Foundation

struct ParsedEvent: Identifiable, Equatable {
    let id = UUID()
    var title: String
    var startDate: Date
    var endDate: Date?
    var location: String?
    var description: String?
    var attendees: [String]?
    var isAllDay: Bool = false
    var reminder: Int?
    
    var duration: TimeInterval? {
        guard let end = endDate else { return nil }
        return end.timeIntervalSince(startDate)
    }
    
    var formattedDuration: String? {
        guard let duration = duration else { return nil }
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        
        if hours > 0 && minutes > 0 {
            return "\(hours)h \(minutes)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        }
        return nil
    }
    
    static func == (lhs: ParsedEvent, rhs: ParsedEvent) -> Bool {
        lhs.id == rhs.id
    }
}

enum ParseError: LocalizedError {
    case emptyInput
    case missingTitle
    case invalidDateFormat
    case ambiguousDate
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .emptyInput:
            return "Please enter event details"
        case .missingTitle:
            return "Could not find event title"
        case .invalidDateFormat:
            return "Could not understand the date/time"
        case .ambiguousDate:
            return "Date is ambiguous, please be more specific"
        case .unknownError:
            return "An error occurred while parsing"
        }
    }
}
