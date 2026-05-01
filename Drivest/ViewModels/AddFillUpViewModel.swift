import Foundation
import SwiftData
import Observation

@Observable
final class AddFillUpViewModel {
    private let modelContext: ModelContext

    var date: Date = Date()
    var pricePerLiterText: String = ""
    var volumeText: String = ""
    var totalCostText: String = ""
    var odometerText: String = ""
    var isFullTank: Bool = true
    var selectedVehicle: Vehicle?
    var selectedFuelType: FuelType?
    var noteText: String = ""
    var discountText: String = ""
    var selectedPhotos: [Data] = []

    var validationError: String?
    let volvoService = VolvoOdometerService()
    let toyotaService = ToyotaOdometerService()

    private var lastEditedFields: (first: FillUpField, second: FillUpField) = (.pricePerLiter, .volume)

    init(modelContext: ModelContext, vehicle: Vehicle?) {
        self.modelContext = modelContext
        self.selectedVehicle = vehicle
        self.selectedFuelType = vehicle?.fuelType
    }

    func onVehicleChanged() {
        selectedFuelType = selectedVehicle?.fuelType
        odometerText = ""
    }

    var pricePerLiter: Double? { pricePerLiterText.parseDouble() }
    var volume: Double? { volumeText.parseDouble() }
    var totalCost: Double? { totalCostText.parseDouble() }
    var odometer: Double? { odometerText.parseDouble() }
    var discount: Double? { discountText.isEmpty ? nil : discountText.parseDouble() }

    var isValid: Bool {
        guard let price = pricePerLiter, price > 0,
              let vol = volume, vol > 0,
              let total = totalCost, total > 0,
              let odo = odometer, odo > 0,
              selectedVehicle != nil else {
            return false
        }
        return true
    }

    func onFieldEdited(_ field: FillUpField) {
        if lastEditedFields.second != field {
            lastEditedFields = (first: lastEditedFields.second, second: field)
        }
        applyAutoCalculation()
    }

    private func applyAutoCalculation() {
        guard let result = FillUpFieldCalculator.autoCalculate(
            lastEditedFields: lastEditedFields,
            pricePerLiter: pricePerLiter,
            volume: volume,
            totalCost: totalCost
        ) else { return }
        switch result.field {
        case .totalCost: totalCostText = result.value
        case .volume: volumeText = result.value
        case .pricePerLiter: pricePerLiterText = result.value
        }
    }

    func validateOdometer() -> Bool {
        guard let vehicle = selectedVehicle, let odo = odometer else {
            return false
        }

        let descriptor = FetchDescriptor<FillUp>(
            predicate: FillUp.predicate(for: vehicle),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let existingFillUps = (try? modelContext.fetch(descriptor)) ?? []
        let minOdometer = existingFillUps.first?.odometerReading ?? vehicle.initialOdometer
        let context = OdometerValidator.Context(min: minOdometer, max: nil)
        if let error = OdometerValidator.validate(odo, context: context) {
            validationError = error
            return false
        }

        validationError = nil
        return true
    }

    // MARK: - Volvo odometer fetch

    func fetchVolvoOdometer() async {
        guard let vin = selectedVehicle?.vin else { return }
        if let result = await volvoService.fetchOdometer(vin: vin) {
            let kmDouble = Double(result.km)
            let display = selectedVehicle?.effectiveDistanceUnit == .miles ? kmDouble * 0.621371 : kmDouble
            odometerText = String(format: "%.0f", display)
            selectedVehicle?.volvoLastSyncAt = result.syncedAt
        }
    }

    // MARK: - Toyota odometer fetch

    func fetchToyotaOdometer() async {
        guard let vin = selectedVehicle?.vin, ToyotaAPIConstants.isConfigured else { return }
        if let result = await toyotaService.fetchOdometer(vin: vin) {
            let kmDouble = Double(result.km)
            let display = selectedVehicle?.effectiveDistanceUnit == .miles ? kmDouble * 0.621371 : kmDouble
            odometerText = String(format: "%.0f", display)
            selectedVehicle?.toyotaLastSyncAt = result.syncedAt
        }
    }

    func save(currencyCode: String? = nil, exchangeRate: Double? = nil) -> Bool {
        guard isValid, validateOdometer() else { return false }
        guard let vehicle = selectedVehicle,
              let price = pricePerLiter,
              let vol = volume,
              let total = totalCost,
              let odo = odometer else { return false }

        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        let fillUp = FillUp(
            date: date,
            pricePerLiter: price,
            volume: vol,
            totalCost: total,
            odometerReading: odo,
            isFullTank: isFullTank,
            vehicle: vehicle,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            fuelType: selectedFuelType
        )
        fillUp.currencyCode = currencyCode
        fillUp.exchangeRate = exchangeRate
        fillUp.discount = discount
        fillUp.photos = selectedPhotos

        modelContext.insert(fillUp)

        // Update vehicle last used
        vehicle.lastUsedAt = Date()

        // Calculate efficiency if full tank
        if isFullTank {
            let descriptor = FetchDescriptor<FillUp>(
                predicate: FillUp.predicate(for: vehicle),
                sortBy: [SortDescriptor(\.date)]
            )
            let allFillUps = (try? modelContext.fetch(descriptor)) ?? []
            fillUp.efficiency = EfficiencyCalculator.calculateEfficiency(
                for: fillUp,
                allFillUps: allFillUps
            )
        }

        Persistence.save(modelContext)
        return true
    }
}

// MARK: - OdometerValidator

struct OdometerValidator {
    struct Context {
        let min: Double   // reading must be strictly above this
        let max: Double?  // reading must be below this if non-nil
    }

    static func validate(_ reading: Double, context: Context) -> String? {
        if reading <= context.min {
            return "Odometer must be greater than \(Int(context.min))"
        }
        if let max = context.max, reading >= max {
            return "Odometer must be less than \(Int(max))"
        }
        return nil
    }
}
