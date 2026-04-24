import SwiftUI
import EventKit

struct CalendarRowView: View {
    let calendar: EKCalendar
    let isSelected: Bool
    let isHovered: Bool
    let isReadOnly: Bool
    let action: () -> Void

    var body: some View {
        HStack {
            Circle()
                .fill(isHovered ? Color(cgColor: calendar.cgColor) : Color(cgColor: calendar.cgColor).opacity(0.8))
                .frame(width: isHovered ? 14 : 12, height: isHovered ? 14 : 12)
                .animation(.easeInOut(duration: 0.15), value: isHovered)

            Text(calendar.title)

            if isReadOnly {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .listRowBackground(
            RoundedRectangle(cornerRadius: 6)
                .fill(isHovered ? Color(cgColor: calendar.cgColor).opacity(0.15) : Color.clear)
        )
    }
}
