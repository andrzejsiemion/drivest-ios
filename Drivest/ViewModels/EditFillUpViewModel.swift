import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class EditFillUpViewModel {
    private let modelContext: ModelContext
    let fillUp: FillUp

    let fields: FillUpFormFields
    var exchangeRateText: String

    init(modelContext: ModelContext, fillUp: FillUp) {
        self.modelContext = modelContext
        self.fillUp = fillUp

        let f = FillUpFormFields()
        f.date = fillUp.date
        f.pricePerLiterText = String(format: "%.2f", fillUp.pricePerLiter)
        f.volumeText = String(format: "%.2f", fillUp.volume)
        f.totalCostText = String(format: "%.2f", fillUp.totalCost)
        f.odometerText = String(format: "%.0f", fillUp.odometerReading)
        f.isFullTank = fillUp.isFullTank
        f.selectedFuelType = fillUp.fuelType
        f.noteText = fillUp.note ?? ""
        f.discountText = fillUp.discount.map { String(format: "%.2f", $0) } ?? ""
        f.selectedPhotos = fillUp.allPhotos
        self.fields = f

        if let rate = fillUp.exchangeRate {
            self.exchangeRateText = String(format: "%.4f", rate)
        } else {
            self.exchangeRateText = ""
        }
    }

    var hasSecondaryCurrency: Bool {
        guard let code = fillUp.currencyCode, !code.isEmpty else { return false }
        return code != AppPreferences.defaultCurrency
    }
    var exchangeRate: Double? { exchangeRateText.parseDouble() }

    var isValid: Bool {
        guard let price = fields.pricePerLiter, price > 0,
              let vol = fields.volume, vol > 0,
              let total = fields.totalCost, total > 0,
              let odo = fields.odometer, odo > 0 else {
            return false
        }
        if hasSecondaryCurrency && (exchangeRate ?? 0) <= 0 { return false }
        return true
    }

    func validateOdometer() -> Bool {
        guard let vehicle = fillUp.vehicle, let odo = fields.odometer else {
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
            fields.validationError = error
            return false
        }

        fields.validationError = nil
        return true
    }

    func fetchVolvoOdometer() async {
        await fields.fetchVolvoOdometer(vehicle: fillUp.vehicle)
    }

    func fetchToyotaOdometer() async {
        await fields.fetchToyotaOdometer(vehicle: fillUp.vehicle)
    }

    func save() -> Bool {
        guard isValid, validateOdometer() else { return false }
        guard let price = fields.pricePerLiter,
              let vol = fields.volume,
              let total = fields.totalCost,
              let odo = fields.odometer else { return false }

        fillUp.date = fields.date
        fillUp.pricePerLiter = price
        fillUp.volume = vol
        fillUp.totalCost = total
        fillUp.odometerReading = odo
        fillUp.isFullTank = fields.isFullTank
        fillUp.fuelType = fields.selectedFuelType

        let trimmedNote = fields.noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        fillUp.note = trimmedNote.isEmpty ? nil : trimmedNote
        fillUp.discount = fields.discount
        fillUp.photos = fields.selectedPhotos
        fillUp.photoData = nil
        if hasSecondaryCurrency { fillUp.exchangeRate = exchangeRate }

        if let vehicle = fillUp.vehicle {
            let descriptor = FetchDescriptor<FillUp>(
                predicate: FillUp.predicate(for: vehicle),
                sortBy: [SortDescriptor(\.date)]
            )
            let allFillUps = (try? modelContext.fetch(descriptor)) ?? []
            EfficiencyCalculator.recalculateAll(for: vehicle, allFillUps: allFillUps)
        }

        Persistence.save(modelContext)

        if let vehicle = fillUp.vehicle {
            Task {
                await ReminderNotificationService.shared.evaluateDistanceReminders(
                    for: vehicle, currentOdometer: odo, context: modelContext
                )
            }
        }

        return true
    }
}
