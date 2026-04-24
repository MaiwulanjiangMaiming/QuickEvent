import Foundation

struct LocationParser {
    static let chineseLocationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "在([\\w\\s]+?)(?=\\s*(?:跟|和|\\d|$))")
    }()

    static let atLocationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "at\\s+([\\w\\s]+?)(?=\\s+(?:with|and|\\d|$))", options: .caseInsensitive)
    }()

    static let inLocationRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "in\\s+([\\w\\s]+?)(?=\\s+(?:with|and|\\d|$))", options: .caseInsensitive)
    }()

    static let prefixRemovalRegex: NSRegularExpression = {
        try! NSRegularExpression(pattern: "(?i)at\\s+|in\\s+")
    }()

    func extractLocation(from input: String) -> String? {
        let fullRange = NSRange(input.startIndex..., in: input)

        if let match = Self.chineseLocationRegex.firstMatch(in: input, options: [], range: fullRange) {
            if let swiftRange = Range(match.range, in: input) {
                let location = String(input[swiftRange])
                    .replacingOccurrences(of: "在", with: "")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !location.isEmpty {
                    return location
                }
            }
        }

        let englishPatterns = [Self.atLocationRegex, Self.inLocationRegex]
        for regex in englishPatterns {
            if let match = regex.firstMatch(in: input, options: [], range: fullRange) {
                if let swiftRange = Range(match.range, in: input) {
                    let matchedStr = String(input[swiftRange])
                    let removalRange = NSRange(matchedStr.startIndex..., in: matchedStr)
                    let location = Self.prefixRemovalRegex.stringByReplacingMatches(
                        in: matchedStr,
                        options: [],
                        range: removalRange,
                        withTemplate: ""
                    ).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !location.isEmpty {
                        return location
                    }
                }
            }
        }

        return nil
    }
}
