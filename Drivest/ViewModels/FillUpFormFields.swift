import Foundation
import Observation

/// Shared form fields and logic used by both AddFillUpViewModel and EditFillUpViewModel.
@MainActor
@Observable
final class FillUpFormFields {
    var pricePerLiterText: String = ""
    var volumeText: String = ""
    var totalCostText: String = ""
    var odometerText: String = ""
    var isFullTank: Bool = true
    var selectedFuelType: FuelType?
    var noteText: String = ""
    var discountText: String = ""
    var selectedPhotos: [Data] = []
    var date: Date = Date()
    var validationError: String?

    let volvoService = VolvoOdometerService()
    let toyotaService = ToyotaOdometerService()
    let location = LocationCaptureFields()

    private var lastEditedFields: (first: FillUpField, second: FillUpField) = (.pricePerLiter, .volume)

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
        case .totalCost: totalCostText = result.value
        case .volume: volumeText = result.value
        case .pricePerLiter: pricePerLiterText = result.value
        }
    }

    // MARK: - Odometer fetch

    func fetchVolvoOdometer(vehicle: Vehicle?) async {
        guard let vin = vehicle?.vin else { return }
        if let result = await volvoService.fetchOdometer(vin: vin) {
            let unit = vehicle?.effectiveDistanceUnit ?? .kilometers
            odometerText = String(format: "%.0f", unit.fromKm(Double(result.km)))
            vehicle?.volvoLastSyncAt = result.syncedAt
        }
    }

    func fetchToyotaOdometer(vehicle: Vehicle?) async {
        guard let vin = vehicle?.vin, ToyotaAPIConstants.isConfigured else { return }
        if let result = await toyotaService.fetchOdometer(vin: vin) {
            let unit = vehicle?.effectiveDistanceUnit ?? .kilometers
            odometerText = String(format: "%.0f", unit.fromKm(Double(result.km)))
            vehicle?.toyotaLastSyncAt = result.syncedAt
        }
    }
}
