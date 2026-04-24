import Foundation

struct ReminderParser {
    static let chineseMinutesBeforeRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*分钟前提醒")
    }()

    static let chineseAdvanceMinutesRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "提前(\\d+)分钟")
    }()

    static let englishRemindBeforeRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "remind\\s+(\\d+)\\s*minutes?\\s*before", options: .caseInsensitive)
    }()

    static let englishReminderColonRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "reminder\\s*:\\s*(\\d+)\\s*minutes?", options: .caseInsensitive)
    }()

    func extractReminder(from input: String) -> Int? {
        let fullRange = NSRange(input.startIndex..., in: input)

        if let match = Self.chineseMinutesBeforeRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                return Int(String(input[swiftRange]).filter { $0.isNumber })
            }
        }

        if let match = Self.chineseAdvanceMinutesRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                return Int(String(input[swiftRange]).filter { $0.isNumber })
            }
        }

        if let match = Self.englishRemindBeforeRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                return Int(String(input[swiftRange]).filter { $0.isNumber })
            }
        }

        if let match = Self.englishReminderColonRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                return Int(String(input[swiftRange]).filter { $0.isNumber })
            }
        }

        return nil
    }
}
