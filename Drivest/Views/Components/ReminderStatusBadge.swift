import SwiftUI

struct ReminderStatusBadge: View {
    let status: ReminderStatus

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var label: String {
        switch status {
        case .pending: String(localized: "Pending")
        case .dueSoon: String(localized: "Due Soon")
        case .overdue: String(localized: "Overdue")
        case .silenced: String(localized: "Silenced")
        }
    }

    private var color: Color {
        switch status {
        case .pending: .green
        case .dueSoon: .orange
        case .overdue: .red
        case .silenced: .gray
        }
    }
}
