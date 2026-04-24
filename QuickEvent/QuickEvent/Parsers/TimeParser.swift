import Foundation

struct TimeParser {
    func parseTime(from normalizedInput: String, originalInput: String) -> (hour: Int, minute: Int)? {
        if let time = parseChineseTime(from: originalInput) {
            return time
        }
        if let time = detectTime(from: normalizedInput) {
            return time
        }
        return nil
    }

    private func parseChineseTime(from input: String) -> (hour: Int, minute: Int)? {
        let afternoonPattern = "下午\\s*(\\d{1,2})点(半)?"
        let morningPattern = "上午\\s*(\\d{1,2})点(半)?"
        let eveningPattern = "晚上\\s*(\\d{1,2})点(半)?"
        let noonPattern = "中午\\s*(\\d{1,2})点(半)?"

        if let match = input.range(of: afternoonPattern, options: .regularExpression) {
            let matched = String(input[match])
            return parseChineseTimeHelper(matched, defaultPeriod: "afternoon")
        }

        if let match = input.range(of: eveningPattern, options: .regularExpression) {
            let matched = String(input[match])
            return parseChineseTimeHelper(matched, defaultPeriod: "evening")
        }

        if let match = input.range(of: morningPattern, options: .regularExpression) {
            let matched = String(input[match])
            return parseChineseTimeHelper(matched, defaultPeriod: "morning")
        }

        if let match = input.range(of: noonPattern, options: .regularExpression) {
            let matched = String(input[match])
            return parseChineseTimeHelper(matched, defaultPeriod: "noon")
        }

        if input.contains("晚上") || input.contains("傍晚") {
            return (19, 0)
        }
        if input.contains("下午") {
            return (14, 0)
        }
        if input.contains("中午") {
            return (12, 0)
        }
        if input.contains("上午") || input.contains("早上") || input.contains("早晨") {
            return (9, 0)
        }
        if input.contains("凌晨") {
            return (2, 0)
        }

        let simplePattern = "(\\d{1,2})点(半)?"
        if let match = input.range(of: simplePattern, options: .regularExpression) {
            let matched = String(input[match])
            if let hour = Int(matched.filter({ $0.isNumber })) {
                let minute = matched.contains("半") ? 30 : 0
                if hour >= 1 && hour <= 5 {
                    return (hour + 12, minute)
                }
                return (hour, minute)
            }
        }

        return nil
    }

    private func parseChineseTimeHelper(_ timeString: String, defaultPeriod: String) -> (hour: Int, minute: Int)? {
        let numbers = timeString.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .compactMap { Int($0) }

        guard let hour = numbers.first else { return nil }
        let minute = timeString.contains("半") ? 30 : 0

        var adjustedHour = hour

        switch defaultPeriod {
        case "afternoon", "evening":
            if hour < 12 {
                adjustedHour = hour + 12
            }
        case "morning":
            if hour == 12 {
                adjustedHour = 0
            }
        case "noon":
            if hour < 12 {
                adjustedHour = hour + 12
            }
        default:
            break
        }

        return (adjustedHour, minute)
    }

    private func detectTime(from input: String) -> (hour: Int, minute: Int)? {
        if let match = input.range(of: "(\\d{1,2}):(\\d{2})", options: .regularExpression) {
            let matched = String(input[match])
            let parts = matched.split(separator: ":")
            if let hour = Int(parts[0]), let minute = Int(parts[1]) {
                return (hour, minute)
            }
        }

        if let match = input.range(of: "(\\d{1,2})\\s*(am|pm)", options: [.regularExpression, .caseInsensitive]) {
            let matched = String(input[match]).lowercased()
            let isPM = matched.contains("pm")
            if let hour = Int(matched.filter({ $0.isNumber })) {
                var adjustedHour = hour
                if isPM && hour != 12 {
                    adjustedHour += 12
                } else if !isPM && hour == 12 {
                    adjustedHour = 0
                }
                return (adjustedHour, 0)
            }
        }

        let lowercased = input.lowercased()
        if lowercased.contains("morning") {
            return (9, 0)
        } else if lowercased.contains("afternoon") {
            return (14, 0)
        } else if lowercased.contains("evening") {
            return (18, 0)
        } else if lowercased.contains("noon") {
            return (12, 0)
        }

        return nil
    }
}
