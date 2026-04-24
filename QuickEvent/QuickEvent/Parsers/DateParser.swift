import Foundation

struct DateParser {
    private let calendar = Calendar.current

    static var dateDetector: NSDataDetector? = {
        try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }()

    func parseDate(from normalizedInput: String, originalInput: String) -> Date? {
        if let detectedDate = detectDateWithNSDataDetector(from: normalizedInput) {
            return detectedDate
        }
        if let relativeDate = parseChineseDate(from: originalInput) ?? parseRelativeDate(from: normalizedInput) {
            return relativeDate
        }
        return nil
    }

    private func detectDateWithNSDataDetector(from input: String) -> Date? {
        guard let detector = Self.dateDetector else {
            return nil
        }
        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        if let match = matches.first, let date = match.date {
            let now = Date()
            if !calendar.isDate(date, inSameDayAs: now) {
                return date
            }
        }
        return nil
    }

    private func parseChineseDate(from input: String) -> Date? {
        let now = Date()

        if input.contains("明天") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        }

        if input.contains("后天") {
            return calendar.date(byAdding: .day, value: 2, to: now)
        }

        if input.contains("今天") {
            return now
        }

        let weekdayMap: [String: Int] = [
            "下周一": 2, "下周二": 3, "下周三": 4, "下周四": 5,
            "下周五": 6, "下周六": 7, "下周日": 1, "下周天": 1
        ]

        for (keyword, weekday) in weekdayMap {
            if input.contains(keyword) {
                return nextWeekday(weekday)
            }
        }

        let thisWeekdayMap: [String: Int] = [
            "周一": 2, "周二": 3, "周三": 4, "周四": 5,
            "周五": 6, "周六": 7, "周日": 1, "周天": 1,
            "星期一": 2, "星期二": 3, "星期三": 4, "星期四": 5,
            "星期五": 6, "星期六": 7, "星期日": 1, "星期天": 1
        ]

        for (keyword, weekday) in thisWeekdayMap {
            if input.contains(keyword) {
                return thisOrNextWeekday(weekday)
            }
        }

        let datePattern = "(\\d{1,2})月(\\d{1,2})[日号]"
        if let match = input.range(of: datePattern, options: .regularExpression) {
            let matched = String(input[match])
            let numbers = matched.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            if numbers.count >= 2 {
                let month = numbers[0]
                let day = numbers[1]
                var components = calendar.dateComponents([.year], from: now)
                components.month = month
                components.day = day
                if let date = calendar.date(from: components) {
                    if date < now {
                        components.year = (components.year ?? 0) + 1
                        return calendar.date(from: components)
                    }
                    return date
                }
            }
        }

        return nil
    }

    private func parseRelativeDate(from input: String) -> Date? {
        let lowercased = input.lowercased()
        let now = Date()

        if lowercased.contains("tomorrow") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        } else if lowercased.contains("day after tomorrow") {
            return calendar.date(byAdding: .day, value: 2, to: now)
        } else if lowercased.contains("next week") {
            return calendar.date(byAdding: .weekOfYear, value: 1, to: now)
        } else if lowercased.contains("next monday") {
            return nextWeekday(2)
        } else if lowercased.contains("next tuesday") {
            return nextWeekday(3)
        } else if lowercased.contains("next wednesday") {
            return nextWeekday(4)
        } else if lowercased.contains("next thursday") {
            return nextWeekday(5)
        } else if lowercased.contains("next friday") {
            return nextWeekday(6)
        } else if lowercased.contains("next saturday") {
            return nextWeekday(7)
        } else if lowercased.contains("next sunday") {
            return nextWeekday(1)
        }

        return nil
    }

    private func nextWeekday(_ targetWeekday: Int) -> Date {
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)
        var daysToAdd = targetWeekday - todayWeekday
        if daysToAdd <= 0 {
            daysToAdd += 7
        }
        return calendar.date(byAdding: .day, value: daysToAdd, to: now) ?? now
    }

    private func thisOrNextWeekday(_ targetWeekday: Int) -> Date {
        let now = Date()
        let todayWeekday = calendar.component(.weekday, from: now)
        let daysToAdd = targetWeekday - todayWeekday
        let actualDays = daysToAdd >= 0 ? daysToAdd : daysToAdd + 7
        return calendar.date(byAdding: .day, value: actualDays, to: now) ?? now
    }
}
