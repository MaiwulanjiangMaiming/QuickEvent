import Foundation
import os

enum AppLogger {
    private static let subsystem = "com.quickevent.app"
    
    static let general = Logger(subsystem: subsystem, category: "General")
    static let parser = Logger(subsystem: subsystem, category: "Parser")
    static let eventKit = Logger(subsystem: subsystem, category: "EventKit")
    static let speech = Logger(subsystem: subsystem, category: "Speech")
    static let ics = Logger(subsystem: subsystem, category: "ICS")
    static let permission = Logger(subsystem: subsystem, category: "Permission")
    static let window = Logger(subsystem: subsystem, category: "Window")
}
