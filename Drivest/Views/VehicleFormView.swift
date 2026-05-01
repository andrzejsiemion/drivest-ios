import SwiftUI
import PhotosUI

struct VehicleFormView: View {
    @Environment(\.dismiss) private var dismiss

    let title: String
    let onSave: (VehicleFormData) -> Void

    @State private var form: VehicleFormData
    @State private var initialOdometerText: String
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showCamera = false

    init(title: String, vehicle: Vehicle? = nil, onSave: @escaping (VehicleFormData) -> Void) {
        self.title = title
        self.onSave = onSave
        _form = State(wrappedValue: VehicleFormData(from: vehicle))
        _initialOdometerText = State(initialValue: vehicle.map { String(format: "%.0f", $0.initialOdometer) } ?? "")
    }

    private var isValid: Bool {
        !form.name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Photo") {
                    HStack {
                        Spacer()
                        VehiclePhotoView(photoData: form.photoData, size: 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label("Choose from Library", systemImage: "photo.on.rectangle")
                    }

                    if cameraAvailable {
                        Button {
                            showCamera = true
                        } label: {
                            Label("Take Photo", systemImage: "camera")
                        }
                    }

                    if form.photoData != nil {
                        Button(role: .destructive) {
                            form.photoData = nil
                        } label: {
                            Label("Remove Photo", systemImage: "trash")
                        }
                    }
                }

                Section("Vehicle Info") {
                    TextField("Name *", text: $form.name)
                        .textInputAutocapitalization(.never)
                    TextField("Make", text: Binding(
                        get: { form.make ?? "" },
                        set: { form.make = $0.isEmpty ? nil : $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    TextField("Model", text: Binding(
                        get: { form.model ?? "" },
                        set: { form.model = $0.isEmpty ? nil : $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    TextField("Description", text: Binding(
                        get: { form.descriptionText ?? "" },
                        set: { form.descriptionText = $0.isEmpty ? nil : $0 }
                    ))
                    .textInputAutocapitalization(.never)
                    TextField("Initial Odometer", text: $initialOdometerText)
                        .keyboardType(.decimalPad)
                    TextField("VIN", text: Binding(
                        get: { form.vin ?? "" },
                        set: { form.vin = $0.isEmpty ? nil : $0.uppercased() }
                    ))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(.system(.body, design: .monospaced))
                    TextField("Registration Plate", text: Binding(
                        get: { form.registrationPlate ?? "" },
                        set: { form.registrationPlate = $0.isEmpty ? nil : $0.uppercased() }
                    ))
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                }

                Section("Units & Fuel") {
                    Picker("Distance Unit", selection: $form.distanceUnit) {
                        Text("Not set").tag(DistanceUnit?.none)
                        ForEach(DistanceUnit.allCases, id: \.self) { unit in
                            Text(LocalizedStringKey(unit.displayName)).tag(DistanceUnit?.some(unit))
                        }
                    }

                    Picker("Fuel Type", selection: $form.fuelType) {
                        Text("Not set").tag(FuelType?.none)
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Text(LocalizedStringKey(type.displayName)).tag(FuelType?.some(type))
                        }
                    }

                    FuelUnitPicker(fuelType: form.fuelType, selectedUnit: $form.fuelUnit)

                    Picker("Efficiency Display", selection: $form.efficiencyDisplayFormat) {
                        Text("Not set").tag(EfficiencyDisplayFormat?.none)
                        ForEach(EfficiencyDisplayFormat.allCases, id: \.self) { format in
                            Text(LocalizedStringKey(format.displayName)).tag(EfficiencyDisplayFormat?.some(format))
                        }
                    }
                }

                Section("Second Tank") {
                    Picker("Fuel Type", selection: $form.secondTankFuelType) {
                        Text("None").tag(FuelType?.none)
                        ForEach(FuelType.allCases, id: \.self) { type in
                            Text(LocalizedStringKey(type.displayName)).tag(FuelType?.some(type))
                        }
                    }
                    if form.secondTankFuelType != nil {
                        FuelUnitPicker(fuelType: form.secondTankFuelType, selectedUnit: $form.secondTankFuelUnit)
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var data = form
                        data.name = form.name.trimmingCharacters(in: .whitespaces)
                        data.initialOdometer = Double(initialOdometerText) ?? 0
                        data.secondTankFuelUnit = form.secondTankFuelType != nil ? form.secondTankFuelUnit : nil
                        onSave(data)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: form.fuelType) { _, newType in
                if let newType, let currentUnit = form.fuelUnit {
                    if !newType.compatibleFuelUnits.contains(currentUnit) {
                        form.fuelUnit = newType.compatibleFuelUnits.first
                    }
                }
            }
            .onChange(of: form.secondTankFuelType) { _, newType in
                if newType == nil {
                    form.secondTankFuelUnit = nil
                } else if let newType, let currentUnit = form.secondTankFuelUnit {
                    if !newType.compatibleFuelUnits.contains(currentUnit) {
                        form.secondTankFuelUnit = newType.compatibleFuelUnits.first
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        form.photoData = ImageCompressor.compress(data) ?? data
                    }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraPickerView(isPresented: $showCamera) { image in
                    Task {
                        if let image, let raw = image.jpegData(compressionQuality: 1.0) {
                            form.photoData = ImageCompressor.compress(raw) ?? raw
                        }
                    }
                }
            }
        }
    }
}

struct VehicleFormData {
    var name: String
    var make: String?
    var model: String?
    var descriptionText: String?
    var vin: String?
    var registrationPlate: String?
    var initialOdometer: Double
    var distanceUnit: DistanceUnit?
    var fuelType: FuelType?
    var fuelUnit: FuelUnit?
    var efficiencyDisplayFormat: EfficiencyDisplayFormat?
    var secondTankFuelType: FuelType?
    var secondTankFuelUnit: FuelUnit?
    var photoData: Data?
}

extension VehicleFormData {
    init(from vehicle: Vehicle?) {
        self.name = vehicle?.name ?? ""
        self.make = vehicle?.make
        self.model = vehicle?.model
        self.descriptionText = vehicle?.descriptionText
        self.vin = vehicle?.vin
        self.registrationPlate = vehicle?.registrationPlate
        self.initialOdometer = vehicle?.initialOdometer ?? 0
        self.distanceUnit = vehicle?.distanceUnit
        self.fuelType = vehicle?.fuelType
        self.fuelUnit = vehicle?.fuelUnit
        self.efficiencyDisplayFormat = vehicle?.efficiencyDisplayFormat
        self.secondTankFuelType = vehicle?.secondTankFuelType
        self.secondTankFuelUnit = vehicle?.secondTankFuelUnit
        self.photoData = vehicle?.photoData
    }
}

