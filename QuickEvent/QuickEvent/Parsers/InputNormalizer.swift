import Foundation

struct InputNormalizer {
    static let replacements: [(original: String, replacement: String)] = [
        ("明天", " tomorrow "),
        ("后天", " day after tomorrow "),
        ("今天", " today "),
        ("下周", " next week "),
        ("上周", " last week "),
        ("上午", " morning "),
        ("下午", " afternoon "),
        ("晚上", " evening "),
        ("中午", " noon "),
        ("点半", ":30"),
        ("点整", ":00"),
        ("点", ":00"),
        ("小时", " hours "),
        ("分钟", " minutes "),
        ("和", " and "),
        ("在", " at "),
        ("跟", " with "),
        ("demain", " tomorrow "),
        ("aujourd'hui", " today "),
        ("après-midi", " afternoon "),
        ("heures", " hours "),
        ("heure", " hour "),
        ("minutes", " minutes "),
        ("minute", " minute "),
        ("mañana", " tomorrow "),
        ("hoy", " today "),
        ("tarde", " afternoon "),
        ("horas", " hours "),
        ("hora", " hour "),
        ("minutos", " minutes "),
        ("minuto", " minute "),
        ("завтра", " tomorrow "),
        ("сегодня", " today "),
        ("утром", " morning "),
        ("днем", " afternoon "),
        ("вечером", " evening "),
        ("часов", " hours "),
        ("часа", " hours "),
        ("час", " hour "),
        ("минут", " minutes "),
        ("минута", " minute "),
        ("минуты", " minutes "),
        ("غدًا", " tomorrow "),
        ("غدا", " tomorrow "),
        ("اليوم", " today "),
        ("صباحًا", " morning "),
        ("صباحا", " morning "),
        ("مساءً", " evening "),
        ("مساء", " evening "),
        ("ساعات", " hours "),
        ("ساعة", " hour "),
        ("دقائق", " minutes "),
        ("دقيقة", " minute ")
    ]

    func normalize(_ input: String) -> String {
        var normalized = input
        for (original, replacement) in Self.replacements {
            normalized = normalized.replacingOccurrences(of: original, with: replacement)
        }
        return normalized
    }
}
