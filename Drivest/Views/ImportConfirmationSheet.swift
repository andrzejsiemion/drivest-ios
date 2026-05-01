import SwiftUI

struct ImportConfirmationSheet: View {
    let preview: VehicleImporter.ImportPreview
    let onConfirm: (VehicleImporter.ConflictStrategy) -> Void
    let onCancel: () -> Void

    @State private var selectedStrategy: VehicleImporter.ConflictStrategy = .merge

    var body: some View {
        NavigationStack {
            Form {
                Section("File Summary") {
                    LabeledContent("Vehicle", value: preview.vehicleName)
                    LabeledContent("Fill-ups", value: "\(preview.fillUpCount)")
                    LabeledContent("Cost entries", value: "\(preview.costEntryCount)")
                    LabeledContent("Exported", value: preview.exportedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if preview.conflictingVehicle != nil {
                    Section {
                        Picker("How to import", selection: $selectedStrategy) {
                            Text("Merge — add new entries only").tag(VehicleImporter.ConflictStrategy.merge)
                            Text("Replace existing data").tag(VehicleImporter.ConflictStrategy.replace)
                            Text("Import as new vehicle").tag(VehicleImporter.ConflictStrategy.createNew)
                        }
                        .pickerStyle(.inline)
                    } header: {
                        Text("\"\(preview.vehicleName)\" already exists")
                    } footer: {
                        strategyFooter
                    }
                }
            }
            .navigationTitle("Import Vehicle Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Import") {
                        onConfirm(preview.conflictingVehicle != nil ? selectedStrategy : .createNew)
                    }
                    .fontWeight(.semibold)
                    .foregroundStyle(selectedStrategy == .replace ? .red : Color.accentColor)
                }
            }
        }
    }

    @ViewBuilder
    private var strategyFooter: some View {
        switch selectedStrategy {
        case .merge:
            Text("Only entries not already present will be added.")
        case .replace:
            Text("All existing fill-ups and costs for this vehicle will be permanently deleted before importing.")
                .foregroundStyle(.red)
        case .createNew:
            Text("A new vehicle named \"\(preview.vehicleName) (imported)\" will be created.")
        }
    }
}
