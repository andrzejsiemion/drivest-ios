import Foundation
import SwiftData
import Observation

@Observable
final class EditFillUpViewModel {
    private let modelContext: ModelContext
    let fillUp: FillUp

    var date: Date
    var pricePerLiterText: String
    var volumeText: String
    var totalCostText: String
    var odometerText: String
    var isFullTank: Bool
    var selectedFuelType: FuelType?
    var noteText: String
    var discountText: String
    var exchangeRateText: String
    var selectedPhotos: [Data]

    var validationError: String?
    let volvoService = VolvoOdometerService()
    let toyotaService = ToyotaOdometerService()

    private var lastEditedFields: (first: FillUpField, second: FillUpField) = (.pricePerLiter, .volume)

    init(modelContext: ModelContext, fillUp: FillUp) {
        self.modelContext = modelContext
        self.fillUp = fillUp
        self.date = fillUp.date
        self.pricePerLiterText = String(format: "%.2f", fillUp.pricePerLiter)
        self.volumeText = String(format: "%.2f", fillUp.volume)
        self.totalCostText = String(format: "%.2f", fillUp.totalCost)
        self.odometerText = String(format: "%.0f", fillUp.odometerReading)
        self.isFullTank = fillUp.isFullTank
        self.selectedFuelType = fillUp.fuelType
        self.noteText = fillUp.note ?? ""
        self.discountText = fillUp.discount.map { String(format: "%.2f", $0) } ?? ""
        self.selectedPhotos = fillUp.allPhotos
        if let rate = fillUp.exchangeRate {
            self.exchangeRateText = String(format: "%.4f", rate)
        } else {
            self.exchangeRateText = ""
        }
    }

    var pricePerLiter: Double? { pricePerLiterText.parseDouble() }
    var volume: Double? { volumeText.parseDouble() }
    var totalCost: Double? { totalCostText.parseDouble() }
    var odometer: Double? { odometerText.parseDouble() }
    var discount: Double? { discountText.isEmpty ? nil : discountText.parseDouble() }

    var hasSecondaryCurrency: Bool {
        guard let code = fillUp.currencyCode, !code.isEmpty else { return false }
        return code != AppPreferences.defaultCurrency
    }
    var exchangeRate: Double? { exchangeRateText.parseDouble() }

    var isValid: Bool {
        guard let price = pricePerLiter, price > 0,
              let vol = volume, vol > 0,
              let total = totalCost, total > 0,
              let odo = odometer, odo > 0 else {
            return false
        }
        if hasSecondaryCurrency && (exchangeRate ?? 0) <= 0 { return false }
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
        guard let vehicle = fillUp.vehicle, let odo = odometer else {
            return false
        }

        let descriptor = FetchDescriptor<FillUp>(
            predicate: FillUp.predicate(for: vehicle),
            sortBy: [SortDescriptor(\.date)]
        )
        let allFillUps = (try? modelContext.fetch(descriptor)) ?? []

        guard let currentIndex = allFillUps.firstIndex(where: { $0.id == fillUp.id }) else {
            return true
        }

        let minOdometer: Double
        if currentIndex > 0 {
            minOdometer = allFillUps[currentIndex - 1].odometerReading
        } else {
            minOdometer = vehicle.initialOdometer
        }

        let maxOdometer: Double?
        if currentIndex < allFillUps.count - 1 {
            maxOdometer = allFillUps[currentIndex + 1].odometerReading
        } else {
            maxOdometer = nil
        }

        let context = OdometerValidator.Context(min: minOdometer, max: maxOdometer)
        if let error = OdometerValidator.validate(odo, context: context) {
            validationError = error
            return false
        }

        validationError = nil
        return true
    }

    // MARK: - Volvo odometer fetch

    func fetchVolvoOdometer() async {
        guard let vin = fillUp.vehicle?.vin else { return }
        if let result = await volvoService.fetchOdometer(vin: vin) {
            let kmDouble = Double(result.km)
            let unit = fillUp.vehicle?.effectiveDistanceUnit
            let display = unit == .miles ? kmDouble * 0.621371 : kmDouble
            odometerText = String(format: "%.0f", display)
            fillUp.vehicle?.volvoLastSyncAt = result.syncedAt
        }
    }

    // MARK: - Toyota odometer fetch

    func fetchToyotaOdometer() async {
        guard let vin = fillUp.vehicle?.vin, ToyotaAPIConstants.isConfigured else { return }
        if let result = await toyotaService.fetchOdometer(vin: vin) {
            let kmDouble = Double(result.km)
            let unit = fillUp.vehicle?.effectiveDistanceUnit
            let display = unit == .miles ? kmDouble * 0.621371 : kmDouble
            odometerText = String(format: "%.0f", display)
            fillUp.vehicle?.toyotaLastSyncAt = result.syncedAt
        }
    }

    func save() -> Bool {
        guard isValid, validateOdometer() else { return false }
        guard let price = pricePerLiter,
              let vol = volume,
              let total = totalCost,
              let odo = odometer else { return false }

        fillUp.date = date
        fillUp.pricePerLiter = price
        fillUp.volume = vol
        fillUp.totalCost = total
        fillUp.odometerReading = odo
        fillUp.isFullTank = isFullTank
        fillUp.fuelType = selectedFuelType

        let trimmedNote = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        fillUp.note = trimmedNote.isEmpty ? nil : trimmedNote
        fillUp.discount = discount
        fillUp.photos = selectedPhotos
        fillUp.photoData = nil
        if hasSecondaryCurrency { fillUp.exchangeRate = exchangeRate }

        // Recalculate efficiency for the entire vehicle
        if let vehicle = fillUp.vehicle {
            let descriptor = FetchDescriptor<FillUp>(
                predicate: FillUp.predicate(for: vehicle),
                sortBy: [SortDescriptor(\.date)]
            )
            let allFillUps = (try? modelContext.fetch(descriptor)) ?? []
            EfficiencyCalculator.recalculateAll(for: vehicle, allFillUps: allFillUps)
        }

        Persistence.save(modelContext)
        return true
    }
}
