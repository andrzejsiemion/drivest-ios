import Foundation
import SwiftData
import Observation

/// Shared state and logic for AddFillUpViewModel and EditFillUpViewModel.
@Observable
class FillUpFormViewModel {
    let modelContext: ModelContext

    var date: Date = Date()
    var pricePerLiterText: String = ""
    var volumeText: String = ""
    var totalCostText: String = ""
    var odometerText: String = ""
    var isFullTank: Bool = true
    var selectedFuelType: FuelType?
    var noteText: String = ""
    var discountText: String = ""
    var selectedPhotos: [Data] = []
    var validationError: String?

    let volvoService: OdometerService
    let toyotaService: OdometerService

    var lastEditedFields: (first: FillUpField, second: FillUpField) = (.pricePerLiter, .volume)

    init(
        modelContext: ModelContext,
        volvoService: OdometerService = VolvoOdometerService(),
        toyotaService: OdometerService = ToyotaOdometerService()
    ) {
        self.modelContext = modelContext
        self.volvoService = volvoService
        self.toyotaService = toyotaService
    }

    // MARK: - Parsed values

    var pricePerLiter: Double? { pricePerLiterText.parseDouble() }
    var volume: Double? { volumeText.parseDouble() }
    var totalCost: Double? { totalCostText.parseDouble() }
    var odometer: Double? { odometerText.parseDouble() }
    var discount: Double? { discountText.isEmpty ? nil : discountText.parseDouble() }

    // MARK: - Auto-calculation

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
        case .totalCost:     totalCostText     = result.value
        case .volume:        volumeText        = result.value
        case .pricePerLiter: pricePerLiterText = result.value
        }
    }

    // MARK: - Odometer fetch

    func fetchVolvoOdometer(vehicle: Vehicle?) async {
        guard let vin = vehicle?.vin else { return }
        if let result = await volvoService.fetchOdometer(vin: vin) {
            let display = convertKm(result.km, for: vehicle)
            odometerText = String(format: "%.0f", display)
            vehicle?.volvoLastSyncAt = result.syncedAt
        }
    }

    func fetchToyotaOdometer(vehicle: Vehicle?) async {
        guard let vin = vehicle?.vin, ToyotaAPIConstants.isConfigured else { return }
        if let result = await toyotaService.fetchOdometer(vin: vin) {
            let display = convertKm(result.km, for: vehicle)
            odometerText = String(format: "%.0f", display)
            vehicle?.toyotaLastSyncAt = result.syncedAt
        }
    }

    private func convertKm(_ km: Int, for vehicle: Vehicle?) -> Double {
        let kmDouble = Double(km)
        return vehicle?.effectiveDistanceUnit == .miles ? kmDouble * 0.621371 : kmDouble
    }
}
