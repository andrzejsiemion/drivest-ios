import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UIKit

struct VehicleDetailView: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var modelContext
    @Query private var allVehicles: [Vehicle]
    @State private var showEditSheet = false
@State private var showImportPicker = false
    @State private var showExportError: String? = nil
    @State private var importFileData: Data? = nil
    @State private var importPreview: VehicleImporter.ImportPreview? = nil
    @State private var showImportConfirmation = false
    @State private var showAllReminders = false

    private var sortedReminders: [Reminder] {
        let odometer = vehicle.currentOdometer
        return vehicle.reminders.sorted { a, b in
            let sa = ReminderEvaluationService.status(for: a, currentOdometer: odometer)
            let sb = ReminderEvaluationService.status(for: b, currentOdometer: odometer)
            return sa.sortOrder < sb.sortOrder
        }
    }

    private func statusColor(_ status: ReminderStatus) -> Color {
        switch status {
        case .overdue: .red
        case .dueSoon: .orange
        case .pending: .secondary
        case .silenced: .secondary
        }
    }

    private func reminderSubtitle(_ reminder: Reminder) -> String {
        switch reminder.reminderType {
        case .date:
            if let date = reminder.dueDate {
                return date.formatted(date: .abbreviated, time: .omitted)
            }
            return ""
        case .distance:
            if let target = reminder.targetOdometer {
                let unit = vehicle.effectiveDistanceUnit
                let displayTarget = unit.fromKm(target)
                return String(format: "%.0f %@", displayTarget, unit.abbreviation)
            }
            return ""
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Spacer()
                    VehiclePhotoView(photoData: vehicle.photoData, size: 100)
                    Spacer()
                }
                .listRowBackground(Color.clear)
            }

            Section("Vehicle Info") {
                LabeledContent("Name", value: vehicle.name)
                if let make = vehicle.make, !make.isEmpty {
                    LabeledContent("Make", value: make)
                }
                if let model = vehicle.model, !model.isEmpty {
                    LabeledContent("Model", value: model)
                }
                if let description = vehicle.descriptionText, !description.isEmpty {
                    LabeledContent("Description", value: description)
                }
                if let vin = vehicle.vin, !vin.isEmpty {
                    LabeledContent("VIN", value: vin)
                        .font(.system(.body, design: .monospaced))
                }
                if let plate = vehicle.registrationPlate, !plate.isEmpty {
                    LabeledContent("License Plate", value: plate)
                }
                LabeledContent("Initial Odometer") {
                    Text(String(format: "%.0f %@", vehicle.initialOdometer, vehicle.effectiveDistanceUnit.abbreviation))
                }
            }

            Section("Units & Fuel") {
                if let distanceUnit = vehicle.distanceUnit {
                    LabeledContent("Distance Unit") { Text(LocalizedStringKey(distanceUnit.displayName)) }
                } else {
                    LabeledContent("Distance Unit") { Text("Not set (default: km)") }
                }

                if let fuelType = vehicle.fuelType {
                    LabeledContent("Fuel Type") { Text(LocalizedStringKey(fuelType.displayName)) }
                } else {
                    LabeledContent("Fuel Type") { Text("Not set") }
                }

                if let fuelUnit = vehicle.fuelUnit {
                    LabeledContent("Fuel Unit") { Text(LocalizedStringKey(fuelUnit.displayName)) }
                } else {
                    LabeledContent("Fuel Unit") { Text("Not set (default: Liters)") }
                }

                if let format = vehicle.efficiencyDisplayFormat {
                    LabeledContent("Efficiency Format") { Text(LocalizedStringKey(format.displayName)) }
                } else {
                    LabeledContent("Efficiency Format") { Text("Not set (default: L/100km)") }
                }
            }

            if let secondType = vehicle.secondTankFuelType {
                Section("Second Tank") {
                    LabeledContent("Fuel Type") { Text(LocalizedStringKey(secondType.displayName)) }
                    if let secondUnit = vehicle.secondTankFuelUnit {
                        LabeledContent("Fuel Unit") { Text(LocalizedStringKey(secondUnit.displayName)) }
                    }
                }
            }

            if VolvoAPIConstants.isConfigured && vehicle.make?.lowercased() == "volvo" {
                Section("Volvo") {
                    if let syncAt = vehicle.volvoLastSyncAt {
                        LabeledContent("Last sync") {
                            Text(syncAt.formatted(.relative(presentation: .named)))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not yet synced")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if ToyotaAPIConstants.isConfigured && vehicle.make?.lowercased() == "toyota" {
                Section("Toyota") {
                    if let syncAt = vehicle.toyotaLastSyncAt {
                        LabeledContent("Last sync") {
                            Text(syncAt.formatted(.relative(presentation: .named)))
                                .foregroundStyle(.secondary)
                        }
                    } else {
                        Text("Not yet synced")
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if vehicle.hasConnectedOBD {
                EVSyncSection(vehicle: vehicle)
            }

            Section("Stats") {
                LabeledContent("Fill-ups recorded") {
                    Text("\(vehicle.fillUps.count)")
                }
                LabeledContent("Last used") {
                    Text(vehicle.lastUsedAt, style: .date)
                }
            }

            Section("Data") {
                Button {
                    exportVehicle()
                } label: {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import Data...", systemImage: "square.and.arrow.down")
                }
            }
        }
        .navigationTitle(vehicle.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEditSheet = true }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            VehicleFormView(title: "Edit Vehicle", vehicle: vehicle) { data in
                let vm = VehicleViewModel(modelContext: modelContext)
                vm.updateVehicle(vehicle, from: data)
            }
        }
        .fileImporter(
            isPresented: $showImportPicker,
            allowedContentTypes: [.json, .drivestBackup],
            allowsMultipleSelection: false
        ) { result in
            guard let url = try? result.get().first else { return }
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            guard let data = try? Data(contentsOf: url) else { return }
            importFileData = data
            importPreview = try? VehicleImporter.preview(from: data, existingVehicles: allVehicles)
            if importPreview != nil { showImportConfirmation = true }
        }
        .sheet(isPresented: $showImportConfirmation) {
            if let preview = importPreview, let data = importFileData {
                ImportConfirmationSheet(preview: preview) { strategy in
                    do {
                        _ = try VehicleImporter.import(from: data, into: modelContext, existingVehicles: allVehicles, strategy: strategy)
                    } catch {
                        showExportError = error.localizedDescription
                    }
                    showImportConfirmation = false
                } onCancel: {
                    showImportConfirmation = false
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { showExportError != nil },
            set: { if !$0 { showExportError = nil } }
        )) {
            Button("OK", role: .cancel) { showExportError = nil }
        } message: {
            Text(showExportError ?? "")
        }
    }

    // MARK: - Export

    private func exportVehicle() {
        do {
            let data = try VehicleExporter.export(vehicle: vehicle)
            let filename = VehicleExporter.filename(for: vehicle)
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
            try data.write(to: tempURL)
            let av = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let root = scene.windows.first?.rootViewController {
                var top: UIViewController = root
                while let next = top.presentedViewController { top = next }
                top.present(av, animated: true)
            }
        } catch {
            showExportError = error.localizedDescription
        }
    }
}

private struct EVSyncSection: View {
    let vehicle: Vehicle
    @Environment(\.modelContext) private var modelContext
    @AppStorage("snapshotLastFetchAt") private var lastFetchAt: Double = 0
    @State private var isFetching = false

    private var lastFetchDisplay: String {
        guard lastFetchAt > 0 else { return NSLocalizedString("Never", comment: "") }
        let date = Date(timeIntervalSince1970: lastFetchAt)
        if Calendar.current.isDateInToday(date) {
            let fmt = DateFormatter()
            fmt.dateStyle = .none
            fmt.timeStyle = .short
            return fmt.string(from: date)
        }
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        fmt.timeStyle = .short
        return fmt.string(from: date)
    }

    var body: some View {
        Section("EV Sync") {
            LabeledContent("Last Synced", value: lastFetchDisplay)
                .foregroundStyle(.secondary)
            Button {
                isFetching = true
                Task {
                    try? await SnapshotFetchService.shared.fetch(vehicle: vehicle, context: modelContext, trigger: .manual)
                    isFetching = false
                }
            } label: {
                HStack {
                    Text("Fetch Now")
                    if isFetching {
                        Spacer()
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
            .disabled(isFetching)
        }
    }
}
