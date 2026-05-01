import Foundation
import SwiftData
import Observation

@Observable
final class VehicleViewModel {
    private let modelContext: ModelContext

    var vehicles: [Vehicle] = []
    var selectedVehicle: Vehicle?

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchVehicles()
    }

    func fetchVehicles() {
        let descriptor = FetchDescriptor<Vehicle>(
            sortBy: [SortDescriptor(\.lastUsedAt, order: .reverse)]
        )
        vehicles = (try? modelContext.fetch(descriptor)) ?? []
        if selectedVehicle == nil {
            selectedVehicle = vehicles.first
        }
    }

    func addVehicle(name: String, initialOdometer: Double) {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let vehicle = Vehicle(name: name, initialOdometer: max(0, initialOdometer))
        modelContext.insert(vehicle)
        Persistence.save(modelContext)
        fetchVehicles()
        selectedVehicle = vehicle
    }

    func createVehicle(from data: VehicleFormData) {
        let vehicle = Vehicle(name: data.name, initialOdometer: max(0, data.initialOdometer))
        vehicle.make = data.make
        vehicle.model = data.model
        vehicle.descriptionText = data.descriptionText
        vehicle.distanceUnit = data.distanceUnit
        vehicle.fuelType = data.fuelType
        vehicle.fuelUnit = data.fuelUnit
        vehicle.efficiencyDisplayFormat = data.efficiencyDisplayFormat
        vehicle.secondTankFuelType = data.secondTankFuelType
        vehicle.secondTankFuelUnit = data.secondTankFuelUnit
        vehicle.photoData = data.photoData
        vehicle.registrationPlate = data.registrationPlate
        modelContext.insert(vehicle)
        Persistence.save(modelContext)
        fetchVehicles()
        selectedVehicle = vehicle
    }

    func updateVehicle(_ vehicle: Vehicle, from data: VehicleFormData) {
        vehicle.name = data.name
        vehicle.make = data.make
        vehicle.model = data.model
        vehicle.descriptionText = data.descriptionText
        vehicle.vin = data.vin
        vehicle.registrationPlate = data.registrationPlate
        vehicle.initialOdometer = max(0, data.initialOdometer)
        vehicle.distanceUnit = data.distanceUnit
        vehicle.fuelType = data.fuelType
        vehicle.fuelUnit = data.fuelUnit
        vehicle.efficiencyDisplayFormat = data.efficiencyDisplayFormat
        vehicle.secondTankFuelType = data.secondTankFuelType
        vehicle.secondTankFuelUnit = data.secondTankFuelUnit
        vehicle.photoData = data.photoData
        Persistence.save(modelContext)
        fetchVehicles()
    }

    func updateVehicle(_ vehicle: Vehicle, name: String, initialOdometer: Double) {
        vehicle.name = name
        vehicle.initialOdometer = initialOdometer
        Persistence.save(modelContext)
        fetchVehicles()
    }

    func deleteVehicle(_ vehicle: Vehicle) {
        if selectedVehicle?.id == vehicle.id {
            selectedVehicle = nil
        }
        modelContext.delete(vehicle)
        Persistence.save(modelContext)
        fetchVehicles()
    }

    func savePhoto(_ data: Data, for vehicle: Vehicle) {
        vehicle.photoData = ImageCompressor.compress(data) ?? data
        Persistence.save(modelContext)
    }

    func removePhoto(for vehicle: Vehicle) {
        vehicle.photoData = nil
        Persistence.save(modelContext)
    }

}
