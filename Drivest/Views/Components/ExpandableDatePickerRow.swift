import SwiftUI

struct ExpandableDatePickerRow: View {
    let label: String
    @Binding var selection: Date

    @State private var isExpanded = false
    @State private var useCalendar = false

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(selection, format: .dateTime.day().month(.wide).year())
                    .foregroundStyle(.primary)
                Image(systemName: useCalendar ? "dial.low" : "calendar")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        useCalendar.toggle()
                        if !isExpanded { isExpanded = true }
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { isExpanded.toggle() }
            }

            if isExpanded {
                if useCalendar {
                    DatePicker(
                        "",
                        selection: $selection,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                } else {
                    DatePicker(
                        "",
                        selection: $selection,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                }
            }
        }
    }
}
