import Foundation

struct DurationParser {
    static let chineseHoursMinutesRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*小时\\s*(\\d*)\\s*分钟")
    }()

    static let chineseHoursRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*小时")
    }()

    static let chineseMinutesRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*分钟")
    }()

    static let englishHMRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*h\\s*(\\d*)\\s*m")
    }()

    static let englishHoursRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*hours?")
    }()

    static let englishMinutesRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(\\d+)\\s*minutes?")
    }()

    func parseDuration(from input: String) -> TimeInterval? {
        let fullRange = NSRange(input.startIndex..., in: input)

        if let match = Self.chineseHoursMinutesRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matched = String(input[swiftRange])
                let numbers = matched.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
                let hours = numbers.first ?? 0
                let minutes = numbers.count > 1 ? numbers[1] : 0
                return TimeInterval(hours * 3600 + minutes * 60)
            }
        }

        if let match = Self.chineseHoursRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matched = String(input[swiftRange])
                if let hours = Int(matched.filter({ $0.isNumber })) {
                    return TimeInterval(hours * 3600)
                }
            }
        }

        if let match = Self.chineseMinutesRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matched = String(input[swiftRange])
                if let minutes = Int(matched.filter({ $0.isNumber })) {
                    return TimeInterval(minutes * 60)
                }
            }
        }

        if let match = Self.englishHMRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matched = String(input[swiftRange])
                let numbers = matched.components(separatedBy: CharacterSet.decimalDigits.inverted).compactMap { Int($0) }
                let hours = numbers.first ?? 0
                let minutes = numbers.count > 1 ? numbers[1] : 0
                return TimeInterval(hours * 3600 + minutes * 60)
            }
        }

        if let match = Self.englishHoursRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matched = String(input[swiftRange])
                if let hours = Int(matched.filter({ $0.isNumber })) {
                    return TimeInterval(hours * 3600)
                }
            }
        }

        if let match = Self.englishMinutesRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let matched = String(input[swiftRange])
                if let minutes = Int(matched.filter({ $0.isNumber })) {
                    return TimeInterval(minutes * 60)
                }
            }
        }

        return nil
    }
}
