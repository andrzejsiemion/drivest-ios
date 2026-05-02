import SwiftUI
import SwiftData

struct VehiclePickerCard: View {
    let vehicle: Vehicle
    let currentOdometer: Double
    let isInteractive: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: { if isInteractive { onTap() } }) {
            HStack(spacing: 10) {
                vehiclePhoto
                Text(vehicle.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(String(format: "%.0f km", currentOdometer))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                if isInteractive {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
    }

    private var vehiclePhoto: some View {
        Group {
            if let data = vehicle.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "fuelpump.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}

struct VehicleDropdownOverlay: View {
    @Environment(VehicleSelectionStore.self) private var store
    @Environment(\.modelContext) private var modelContext

    let vehicles: [Vehicle]
    @Binding var isShowing: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(vehicles, id: \.id) { vehicle in
                Button {
                    store.selectVehicle(vehicle, modelContext: modelContext)
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        isShowing = false
                    }
                } label: {
                    HStack(spacing: 10) {
                        vehiclePhoto(vehicle)
                        Text(vehicle.name)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                        Spacer()
                        if store.selectedVehicle?.id == vehicle.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                                .font(.subheadline)
                        }
                    }
                    .contentShape(Rectangle())
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                if vehicle.id != vehicles.last?.id {
                    Divider().padding(.leading, 60)
                }
            }
        }
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }

    private func vehiclePhoto(_ vehicle: Vehicle) -> some View {
        Group {
            if let data = vehicle.photoData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "fuelpump.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.accentColor)
            }
        }
        .frame(width: 36, height: 36)
        .clipShape(Circle())
    }
}

struct VehiclePickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(VehicleSelectionStore.self) private var store
    @Environment(\.modelContext) private var modelContext
    @Query private var allVehicles: [Vehicle]
    @State private var showAddVehicle = false

    let vehicles: [Vehicle]

    var body: some View {
        NavigationStack {
            List {
                ForEach(vehicles, id: \.id) { vehicle in
                    Button {
                        store.selectVehicle(vehicle, modelContext: modelContext)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            VehiclePhotoView(photoData: vehicle.photoData, size: 36)
                            Text(vehicle.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            if store.selectedVehicle?.id == vehicle.id {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteVehicle(vehicle)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Select Vehicle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddVehicle = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddVehicle) {
                VehicleFormView(title: "New Vehicle") { formData in
                    let vm = VehicleViewModel(modelContext: modelContext)
                    vm.createVehicle(from: formData)
                }
            }
        }
    }

    private func deleteVehicle(_ vehicle: Vehicle) {
        let replacement = allVehicles.first(where: { $0.id != vehicle.id })
        // Nil out selection before deletion so no view accesses properties
        // of the about-to-be-detached model object during re-render.
        store.selectedVehicle = nil
        modelContext.delete(vehicle)
        Persistence.save(modelContext)
        store.selectedVehicle = replacement
    }
}
