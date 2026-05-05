import Foundation
import SwiftData
import Observation

@MainActor
@Observable
final class AddFillUpViewModel {
    private let modelContext: ModelContext

    let fields = FillUpFormFields()
    var selectedVehicle: Vehicle?

    init(modelContext: ModelContext, vehicle: Vehicle?) {
        self.modelContext = modelContext
        self.selectedVehicle = vehicle
        self.fields.selectedFuelType = vehicle?.fuelType
    }

    func onVehicleChanged() {
        fields.selectedFuelType = selectedVehicle?.fuelType
        fields.odometerText = ""
    }

    var isValid: Bool {
        guard let price = fields.pricePerLiter, price > 0,
              let vol = fields.volume, vol > 0,
              let total = fields.totalCost, total > 0,
              let odo = fields.odometer, odo > 0,
              selectedVehicle != nil else {
            return false
        }
        return true
    }

    func validateOdometer() -> Bool {
        guard let vehicle = selectedVehicle, let odo = fields.odometer else {
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
            fields.validationError = error
            return false
        }

        fields.validationError = nil
        return true
    }

    func fetchVolvoOdometer() async {
        await fields.fetchVolvoOdometer(vehicle: selectedVehicle)
    }

    func fetchToyotaOdometer() async {
        await fields.fetchToyotaOdometer(vehicle: selectedVehicle)
    }

    func save(currencyCode: String? = nil, exchangeRate: Double? = nil) -> Bool {
        guard isValid, validateOdometer() else { return false }
        guard let vehicle = selectedVehicle,
              let price = fields.pricePerLiter,
              let vol = fields.volume,
              let total = fields.totalCost,
              let odo = fields.odometer else { return false }

        let trimmedNote = fields.noteText.trimmingCharacters(in: .whitespacesAndNewlines)

        let fillUp = FillUp(
            date: fields.date,
            pricePerLiter: price,
            volume: vol,
            totalCost: total,
            odometerReading: odo,
            isFullTank: fields.isFullTank,
            vehicle: vehicle,
            note: trimmedNote.isEmpty ? nil : trimmedNote,
            fuelType: fields.selectedFuelType
        )
        fillUp.currencyCode = currencyCode
        fillUp.exchangeRate = exchangeRate
        fillUp.discount = fields.discount
        fillUp.photos = fields.selectedPhotos

        modelContext.insert(fillUp)

        vehicle.lastUsedAt = Date()

        if fields.isFullTank {
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

        Task {
            await ReminderNotificationService.shared.evaluateDistanceReminders(
                for: vehicle, currentOdometer: odo, context: modelContext
            )
        }

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
