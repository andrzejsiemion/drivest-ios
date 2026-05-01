import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct VehicleListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VehicleSelectionStore.self) private var store
    @Query(sort: \Vehicle.lastUsedAt, order: .reverse) private var vehicles: [Vehicle]
    @State private var showAddVehicle = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteConfirmation = false
    @State private var showImportPicker = false
    @State private var importData: Data? = nil
    @State private var importPreview: VehicleImporter.ImportPreview? = nil
    @State private var showImportConfirmation = false
    @State private var importError: String? = nil

    var body: some View {
        Group {
            if vehicles.isEmpty {
                EmptyStateView(
                    title: "No Vehicles",
                    message: "Add your first vehicle to start tracking fuel costs.",
                    actionLabel: "Add Vehicle"
                ) {
                    showAddVehicle = true
                }
            } else {
                List {
                    ForEach(vehicles, id: \.id) { vehicle in
                        NavigationLink {
                            VehicleDetailView(vehicle: vehicle)
                        } label: {
                            VehicleRow(vehicle: vehicle)
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                vehicleToDelete = vehicle
                                showDeleteConfirmation = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Vehicles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddVehicle = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showImportPicker = true
                } label: {
                    Label("Import", systemImage: "square.and.arrow.down")
                }
            }
        }
        .sheet(isPresented: $showAddVehicle) {
            VehicleFormView(title: "Add Vehicle") { data in
                let vm = VehicleViewModel(modelContext: modelContext)
                vm.createVehicle(from: data)
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
            importData = data
            importPreview = try? VehicleImporter.preview(from: data, existingVehicles: vehicles)
            if importPreview != nil { showImportConfirmation = true }
        }
        .sheet(isPresented: $showImportConfirmation) {
            if let preview = importPreview, let data = importData {
                ImportConfirmationSheet(preview: preview) { strategy in
                    do {
                        _ = try VehicleImporter.import(from: data, into: modelContext, existingVehicles: vehicles, strategy: strategy)
                    } catch {
                        importError = error.localizedDescription
                    }
                    showImportConfirmation = false
                } onCancel: {
                    showImportConfirmation = false
                }
            }
        }
        .alert("Error", isPresented: Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )) {
            Button("OK", role: .cancel) { importError = nil }
        } message: {
            Text(importError ?? "")
        }
        .alert("Delete Vehicle?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                vehicleToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let vehicle = vehicleToDelete {
                    if store.selectedVehicle?.id == vehicle.id {
                        store.selectedVehicle = nil
                    }
                    let vm = VehicleViewModel(modelContext: modelContext)
                    vm.deleteVehicle(vehicle)
                }
                vehicleToDelete = nil
            }
        } message: {
            Text("This will permanently delete the vehicle and all its fill-up history. This action cannot be undone.")
        }
    }
}

private struct VehicleRow: View {
    let vehicle: Vehicle
    private let evaluationService = ReminderEvaluationService()

    var body: some View {
        HStack(spacing: 12) {
            VehiclePhotoView(photoData: vehicle.photoData, size: 44)
                .overlay(alignment: .topTrailing) {
                    if evaluationService.hasDueReminders(for: vehicle) {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 10, height: 10)
                            .offset(x: 2, y: -2)
                    }
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(vehicle.name)
                    .font(.headline)
                if let makeModel = vehicle.makeModelDisplay {
                    Text(makeModel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                if let fuelType = vehicle.fuelType {
                    Text(fuelType.displayName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}
