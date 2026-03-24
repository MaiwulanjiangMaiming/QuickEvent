//
//  NaturalLanguageParser.swift
//  QuickEvent
//
//  Created by Maiwulanjiang Maiming
//  GitHub: https://github.com/MaiwulanjiangMaiming/Calendar_ics_generation_helper
//

import Foundation

class NaturalLanguageParser: ObservableObject {
    private let calendar = Calendar.current
    
    func parse(_ input: String) async throws -> ParsedEvent {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmed.isEmpty else {
            throw ParseError.emptyInput
        }
        
        let normalizedInput = normalizeInput(trimmed)
        
        let title = extractTitle(from: normalizedInput, original: trimmed)
        guard !title.isEmpty else {
            throw ParseError.missingTitle
        }
        
        let (startDate, endDate) = try extractDateTime(from: normalizedInput, original: trimmed)
        
        let location = extractLocation(from: normalizedInput)
        let description = extractDescription(from: normalizedInput)
        let attendees = extractAttendees(from: normalizedInput)
        let reminder = extractReminder(from: normalizedInput)
        
        return ParsedEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            description: description,
            attendees: attendees,
            reminder: reminder
        )
    }
    
    private func normalizeInput(_ input: String) -> String {
        var normalized = input
        
        let replacements: [String: String] = [
            "明天": " tomorrow ",
            "后天": " day after tomorrow ",
            "今天": " today ",
            "下周": " next week ",
            "上周": " last week ",
            "上午": " morning ",
            "下午": " afternoon ",
            "晚上": " evening ",
            "中午": " noon ",
            "点半": ":30",
            "点整": ":00",
            "点": ":00",
            "小时": " hours ",
            "分钟": " minutes ",
            "和": " and ",
            "在": " at ",
            "跟": " with ",
            "demain": " tomorrow ",
            "aujourd'hui": " today ",
            "après-midi": " afternoon ",
            "heures": " hours ",
            "heure": " hour ",
            "minutes": " minutes ",
            "minute": " minute ",
            "mañana": " tomorrow ",
            "hoy": " today ",
            "tarde": " afternoon ",
            "horas": " hours ",
            "hora": " hour ",
            "minutos": " minutes ",
            "minuto": " minute ",
            "завтра": " tomorrow ",
            "сегодня": " today ",
            "утром": " morning ",
            "днем": " afternoon ",
            "вечером": " evening ",
            "часов": " hours ",
            "часа": " hours ",
            "час": " hour ",
            "минут": " minutes ",
            "минута": " minute ",
            "минуты": " minutes ",
            "غدًا": " tomorrow ",
            "غدا": " tomorrow ",
            "اليوم": " today ",
            "صباحًا": " morning ",
            "صباحا": " morning ",
            "مساءً": " evening ",
            "مساء": " evening ",
            "ساعات": " hours ",
            "ساعة": " hour ",
            "دقائق": " minutes ",
            "دقيقة": " minute "
        ]
        
        for (chinese, english) in replacements {
            normalized = normalized.replacingOccurrences(of: chinese, with: english)
        }
        
        return normalized
    }
    
    private func extractTitle(from input: String, original: String) -> String {
        var title = original
        
        let timePatterns = [
            "\\d{1,2}:\\d{2}",
            "\\d{1,2}点\\d{0,2}",
            "\\d{1,2}点半",
            "明天|后天|今天|下周|上周",
            "上午|下午|晚上|中午",
            "\\d+\\s*小时|\\d+\\s*小时",
            "\\d+\\s*分钟|\\d+\\s*分钟",
            "\\d+h\\s*\\d*m",
            "\\d+h"
        ]
        
        for pattern in timePatterns {
            title = title.replacingOccurrences(
                of: pattern,
                with: "",
                options: .regularExpression,
                range: nil
            )
        }
        
        let locationPatterns = [
            "在\\s*\\S+",
            "at\\s+\\S+",
            "in\\s+\\S+"
        ]
        
        for pattern in locationPatterns {
            title = title.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive],
                range: nil
            )
        }
        
        title = title
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        return title
    }
    
    private func extractDateTime(from input: String, original: String) throws -> (Date, Date?) {
        let now = Date()
        var startDate = now
        var duration: TimeInterval = 3600
        var hasExplicitTime = false
        
        // Step 1: Parse date
        if let detectedDate = detectDateWithNSDataDetector(from: input) {
            startDate = detectedDate
        } else if let relativeDate = parseChineseDate(from: original) ?? parseRelativeDate(from: input) {
            startDate = relativeDate
        }
        
        // Step 2: Parse time - check original input first for Chinese time
        if let detectedTime = parseChineseTime(from: original) ?? detectTime(from: input) {
            let cal = Calendar.current
            var components = cal.dateComponents([.year, .month, .day], from: startDate)
            components.hour = detectedTime.hour
            components.minute = detectedTime.minute
            if let newDate = cal.date(from: components) {
                startDate = newDate
                hasExplicitTime = true
            }
        }
        
        // Step 3: If no explicit time and it's today, use next hour
        if !hasExplicitTime && calendar.isDateInToday(startDate) {
            let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
            var components = calendar.dateComponents([.year, .month, .day, .hour], from: nextHour)
            components.minute = 0
            if let newDate = calendar.date(from: components) {
                startDate = newDate
            }
        }
        
        // Step 4: Parse duration
        if let detectedDuration = detectDuration(from: input) {
            duration = detectedDuration
        }
        
        let endDate = startDate.addingTimeInterval(duration)
        
        return (startDate, endDate)
    }
    
    private func detectDateWithNSDataDetector(from input: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }
        
        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        
        if let match = matches.first, let date = match.date {
            // Only use detector result if it's not today at current time
            let now = Date()
            if !calendar.isDate(date, inSameDayAs: now) {
                return date
            }
        }
        
        return nil
    }
    
    private func parseChineseDate(from input: String) -> Date? {
        let now = Date()
        
        // 明天
        if input.contains("明天") {
            return calendar.date(byAdding: .day, value: 1, to: now)
        }
        
        // 后天
        if input.contains("后天") {
            return calendar.date(byAdding: .day, value: 2, to: now)
        }
        
        // 今天
        if input.contains("今天") {
            return now
        }
        
        // 下周一/二/三/四/五/六/日
        let weekdayMap: [String: Int] = [
            "下周一": 2, "下周二": 3, "下周三": 4, "下周四": 5,
            "下周五": 6, "下周六": 7, "下周日": 1, "下周天": 1
        ]
        
        for (keyword, weekday) in weekdayMap {
            if input.contains(keyword) {
                return nextWeekday(weekday)
            }
        }
        
        // 周一/周二 etc (this week)
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
        
        // X月X日 format
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
                    // If the date has passed this year, use next year
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
        // If same day or future day this week, use it; otherwise next week
        let actualDays = daysToAdd >= 0 ? daysToAdd : daysToAdd + 7
        return calendar.date(byAdding: .day, value: actualDays, to: now) ?? now
    }
    
    private func parseChineseTime(from input: String) -> (hour: Int, minute: Int)? {
        // First check for time with numbers: 上午/下午/晚上/中午 X点 or X点半
        let afternoonPattern = "下午\\s*(\\d{1,2})点(半)?"
        let morningPattern = "上午\\s*(\\d{1,2})点(半)?"
        let eveningPattern = "晚上\\s*(\\d{1,2})点(半)?"
        let noonPattern = "中午\\s*(\\d{1,2})点(半)?"
        
        // Check afternoon first (most common)
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
        
        // Check for pure time keywords without numbers
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
        
        // Simple X点 or X点半
        let simplePattern = "(\\d{1,2})点(半)?"
        if let match = input.range(of: simplePattern, options: .regularExpression) {
            let matched = String(input[match])
            if let hour = Int(matched.filter({ $0.isNumber })) {
                let minute = matched.contains("半") ? 30 : 0
                // If hour is between 1-5, assume afternoon for Chinese
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
        // Pattern: HH:MM
        if let match = input.range(of: "(\\d{1,2}):(\\d{2})", options: .regularExpression) {
            let matched = String(input[match])
            let parts = matched.split(separator: ":")
            if let hour = Int(parts[0]), let minute = Int(parts[1]) {
                return (hour, minute)
            }
        }
        
        // Pattern: X am/pm
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
        
        // Time keywords
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
    
    private func detectDuration(from input: String) -> TimeInterval? {
        // Pattern: X小时 Y分钟
        if let match = input.range(of: "(\\d+)\\s*小时\\s*(\\d*)\\s*分钟", options: .regularExpression) {
            let matched = String(input[match])
            let numbers = matched.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            let hours = numbers.first ?? 0
            let minutes = numbers.count > 1 ? (numbers[1]) : 0
            return TimeInterval(hours * 3600 + minutes * 60)
        }
        
        // Pattern: X小时
        if let match = input.range(of: "(\\d+)\\s*小时", options: .regularExpression) {
            let matched = String(input[match])
            if let hours = Int(matched.filter({ $0.isNumber })) {
                return TimeInterval(hours * 3600)
            }
        }
        
        // Pattern: X分钟
        if let match = input.range(of: "(\\d+)\\s*分钟", options: .regularExpression) {
            let matched = String(input[match])
            if let minutes = Int(matched.filter({ $0.isNumber })) {
                return TimeInterval(minutes * 60)
            }
        }
        
        // English patterns
        if let match = input.range(of: "(\\d+)\\s*h\\s*(\\d*)\\s*m", options: .regularExpression) {
            let matched = String(input[match])
            let numbers = matched.components(separatedBy: CharacterSet.decimalDigits.inverted)
                .compactMap { Int($0) }
            let hours = numbers.first ?? 0
            let minutes = numbers.count > 1 ? (numbers[1]) : 0
            return TimeInterval(hours * 3600 + minutes * 60)
        }
        
        if let match = input.range(of: "(\\d+)\\s*hours?", options: .regularExpression) {
            let matched = String(input[match])
            if let hours = Int(matched.filter({ $0.isNumber })) {
                return TimeInterval(hours * 3600)
            }
        }
        
        if let match = input.range(of: "(\\d+)\\s*minutes?", options: .regularExpression) {
            let matched = String(input[match])
            if let minutes = Int(matched.filter({ $0.isNumber })) {
                return TimeInterval(minutes * 60)
            }
        }
        
        return nil
    }
    
    private func extractLocation(from input: String) -> String? {
        // Chinese: 在XXX
        if let match = input.range(of: "在([\\w\\s]+?)(?=\\s*(?:跟|和|\\d|$))", options: .regularExpression) {
            let location = String(input[match])
                .replacingOccurrences(of: "在", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !location.isEmpty {
                return location
            }
        }
        
        // English patterns
        let patterns = [
            "at\\s+([\\w\\s]+?)(?=\\s+(?:with|and|\\d|$))",
            "in\\s+([\\w\\s]+?)(?=\\s+(?:with|and|\\d|$))"
        ]
        
        for pattern in patterns {
            if let match = input.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                let location = String(input[match])
                    .replacingOccurrences(of: "(?i)at\\s+|in\\s+", with: "", options: .regularExpression)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !location.isEmpty {
                    return location
                }
            }
        }
        
        return nil
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
    
    private func extractAttendees(from input: String) -> [String]? {
        // Chinese: 跟XXX
        if let match = input.range(of: "跟([\\w\\s,、]+?)(?=\\s*(?:在|\\d|$))", options: .regularExpression) {
            let attendeesStr = String(input[match])
                .replacingOccurrences(of: "跟", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let attendees = attendeesStr
                .split(separator: ",")
                .flatMap { $0.split(separator: "、") }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            return attendees.isEmpty ? nil : attendees
        }
        
        // English
        if let match = input.range(of: "with\\s+([\\w\\s,]+?)(?=\\s+(?:at|in|\\d|$))", options: [.regularExpression, .caseInsensitive]) {
            let attendeesStr = String(input[match])
                .replacingOccurrences(of: "(?i)with\\s+", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            let attendees = attendeesStr
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            return attendees.isEmpty ? nil : attendees
        }
        
        return nil
    }
    
    private func extractReminder(from input: String) -> Int? {
        // Chinese patterns
        if let match = input.range(of: "(\\d+)\\s*分钟前提醒", options: .regularExpression) {
            return Int(String(input[match]).filter { $0.isNumber })
        }
        
        if let match = input.range(of: "提前(\\d+)分钟", options: .regularExpression) {
            return Int(String(input[match]).filter { $0.isNumber })
        }
        
        // English patterns
        let patterns = [
            "remind\\s+(\\d+)\\s*minutes?\\s*before",
            "reminder\\s*:\\s*(\\d+)\\s*minutes?"
        ]
        
        for pattern in patterns {
            if let match = input.range(of: pattern, options: [.regularExpression, .caseInsensitive]) {
                return Int(String(input[match]).filter { $0.isNumber })
            }
        }
        
        return nil
    }
}
