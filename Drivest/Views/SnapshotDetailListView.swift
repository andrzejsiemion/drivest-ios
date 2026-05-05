import SwiftUI
import SwiftData

struct SnapshotDetailListView: View {
    let period: EVPeriod
    let vehicle: Vehicle

    @Environment(\.modelContext) private var modelContext
    @State private var isFetching = false

    private var snapshots: [EnergySnapshot] {
        let end = period.endDate ?? Date.distantFuture
        return vehicle.energySnapshots
            .filter { $0.fetchedAt >= period.startDate && $0.fetchedAt <= end }
            .sorted { $0.fetchedAt > $1.fetchedAt }
    }

    var body: some View {
        Group {
            if snapshots.isEmpty {
                ContentUnavailableView(
                    "No Snapshots",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("No API readings have been recorded for this period yet.")
                )
            } else {
                List(snapshots) { snapshot in
                    SnapshotRow(snapshot: snapshot)
                        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                }
            }
        }
        .navigationTitle("Snapshot History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isFetching = true
                    Task {
                        try? await SnapshotFetchService.shared.fetch(vehicle: vehicle, context: modelContext, trigger: .manual)
                        isFetching = false
                    }
                } label: {
                    if isFetching {
                        ProgressView().scaleEffect(0.75)
                    } else {
                        Image(systemName: "arrow.down.circle")
                    }
                }
                .disabled(isFetching)
            }
        }
    }
}

// MARK: - Row

private struct SnapshotRow: View {
    let snapshot: EnergySnapshot

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text(snapshot.fetchedAt, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    .font(.subheadline)
                    .fontWeight(.medium)

                HStack(spacing: 12) {
                    Text(formattedOdometer)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()

                    if let soc = snapshot.socPercent {
                        Text("\(soc)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    } else {
                        Text("—")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            TriggerBadge(trigger: FetchTrigger(rawValue: snapshot.fetchTrigger) ?? .scheduled)
        }
    }

    private var formattedOdometer: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        let formatted = formatter.string(from: NSNumber(value: snapshot.odometerKm)) ?? "\(Int(snapshot.odometerKm))"
        return "\(formatted) km"
    }
}

// MARK: - Badge

private struct TriggerBadge: View {
    let trigger: FetchTrigger

    var body: some View {
        Text(label)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color)
            .clipShape(Capsule())
    }

    private var label: LocalizedStringKey {
        switch trigger {
        case .manual: "Manual"
        default:      "Scheduled"
        }
    }

    private var color: Color {
        switch trigger {
        case .manual: .accentColor
        default:      Color(.systemGray3)
        }
    }
}
