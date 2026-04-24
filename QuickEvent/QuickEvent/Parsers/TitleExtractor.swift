import Foundation

struct TitleExtractor {
    static let timeRegexPatterns: [NSRegularExpression] = {
        [
            "\\d{1,2}:\\d{2}",
            "\\d{1,2}点\\d{0,2}",
            "\\d{1,2}点半",
            "明天|后天|今天|下周|上周",
            "上午|下午|晚上|中午",
            "\\d+\\s*小时",
            "\\d+\\s*分钟",
            "\\d+h\\s*\\d*m",
            "\\d+h"
        ].map { try! NSRegularExpression(pattern: $0) }
    }()

    static let locationRegexPatterns: [NSRegularExpression] = {
        let patterns: [(String, NSRegularExpression.Options)] = [
            ("在\\s*\\S+", []),
            ("at\\s+\\S+", .caseInsensitive),
            ("in\\s+\\S+", .caseInsensitive)
        ]
        return patterns.map { try! NSRegularExpression(pattern: $0.0, options: $0.1) }
    }()

    static let whitespaceRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "\\s+")
    }()

    func extractTitle(from normalizedInput: String, original: String) -> String {
        var title = original

        for regex in Self.timeRegexPatterns {
            let range = NSRange(title.startIndex..., in: title)
            title = regex.stringByReplacingMatches(in: title, options: [], range: range, withTemplate: "")
        }

        for regex in Self.locationRegexPatterns {
            let range = NSRange(title.startIndex..., in: title)
            title = regex.stringByReplacingMatches(in: title, options: [], range: range, withTemplate: "")
        }

        let whitespaceRange = NSRange(title.startIndex..., in: title)
        title = Self.whitespaceRegex.stringByReplacingMatches(in: title, options: [], range: whitespaceRange, withTemplate: " ")

        title = title.trimmingCharacters(in: .whitespacesAndNewlines)

        return title
    }
}
