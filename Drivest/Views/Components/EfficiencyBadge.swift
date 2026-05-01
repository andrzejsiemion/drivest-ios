import SwiftUI

struct EfficiencyBadge: View {
    let efficiency: Double?
    let isOnlyEntry: Bool

    init(efficiency: Double?, isOnlyEntry: Bool = false) {
        self.efficiency = efficiency
        self.isOnlyEntry = isOnlyEntry
    }

    var body: some View {
        if let efficiency {
            Text(String(format: "%.1f L/100km", efficiency))
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(efficiencyColor.opacity(0.15))
                .foregroundStyle(efficiencyColor)
                .clipShape(Capsule())
        } else if isOnlyEntry {
            Text("Add another fill-up to see efficiency")
                .font(.caption2)
                .foregroundStyle(.secondary)
        } else {
            Text("—")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var efficiencyColor: Color {
        guard let efficiency else { return .secondary }
        if efficiency < 6 { return .green }
        if efficiency < 9 { return .orange }
        return .red
    }
}
