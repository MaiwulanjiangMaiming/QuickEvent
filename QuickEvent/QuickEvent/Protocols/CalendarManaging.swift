import Foundation
import EventKit

protocol CalendarManaging: AnyObject {
    var hasAccess: Bool { get }
    var calendars: [EKCalendar] { get }
    var writableCalendars: [EKCalendar] { get }
    var readonlyCalendars: [EKCalendar] { get }

    func requestAccess()
    func addEvent(_ parsedEvent: ParsedEvent, to calendar: EKCalendar?) throws
    func isCalendarReadOnly(_ calendar: EKCalendar) -> Bool
    func openCalendarApp()
    func openSystemPreferences()
}
