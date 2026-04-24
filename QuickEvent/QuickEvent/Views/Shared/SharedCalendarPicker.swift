import SwiftUI
import EventKit

struct SharedCalendarPicker: View {
    let calendars: [EKCalendar]
    let selectedCalendarID: String?
    let onSelectCalendar: (EKCalendar) -> Void
    let isReadOnly: (EKCalendar) -> Bool

    @State private var hoveredCalendar: EKCalendar?
    @State private var showReadOnlyWarning: Bool = false
    @State private var pendingCalendar: EKCalendar?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Calendar:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Menu {
                let writable = calendars.filter { !isReadOnly($0) }
                let readonly = calendars.filter { isReadOnly($0) }

                if !writable.isEmpty {
                    Section("Writable Calendars") {
                        ForEach(writable, id: \.calendarIdentifier) { calendar in
                            Button(action: { selectCalendar(calendar) }) {
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                    if selectedCalendarID == calendar.calendarIdentifier {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }

                if !readonly.isEmpty {
                    Section("Read-Only Calendars") {
                        ForEach(readonly, id: \.calendarIdentifier) { calendar in
                            Button(action: { selectCalendar(calendar) }) {
                                HStack {
                                    Circle()
                                        .fill(Color(cgColor: calendar.cgColor))
                                        .frame(width: 10, height: 10)
                                    Text(calendar.title)
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    if selectedCalendarID == calendar.calendarIdentifier {
                                        Spacer()
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let calendar = calendars.first(where: { $0.calendarIdentifier == selectedCalendarID }) {
                        Circle()
                            .fill(Color(cgColor: calendar.cgColor))
                            .frame(width: 12, height: 12)
                        Text(calendar.title)
                            .foregroundStyle(.primary)
                        if isReadOnly(calendar) {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Select Calendar")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
        }
        .alert("Read-Only Calendar", isPresented: $showReadOnlyWarning) {
            Button("Cancel", role: .cancel) {
                pendingCalendar = nil
            }
            Button("Continue Anyway") {
                if let calendar = pendingCalendar {
                    onSelectCalendar(calendar)
                }
                pendingCalendar = nil
            }
        } message: {
            Text("This calendar is read-only. Events may not be saved. Continue anyway?")
        }
    }

    private func selectCalendar(_ calendar: EKCalendar) {
        if isReadOnly(calendar) {
            pendingCalendar = calendar
            showReadOnlyWarning = true
        } else {
            onSelectCalendar(calendar)
        }
    }
}
