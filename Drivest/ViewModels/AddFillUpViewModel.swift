import Foundation
import SwiftData
import Observation
import CoreLocation

@MainActor
@Observable
final class AddFillUpViewModel {
    private let modelContext: ModelContext

    let fields = FillUpFormFields()
    let locationService = LocationService()
    var selectedVehicle: Vehicle?

    /// User-picked coordinate from the long-press map picker. When non-nil it
    /// takes precedence over the live GPS fix for both display and save.
    /// Cleared by `refreshLocation()` so the user can fall back to live GPS.
    var manualLocationOverride: CLLocation?

    /// Coordinate that should be displayed in the form and persisted on save.
    /// Manual override wins; otherwise the freshest GPS fix.
    var effectiveLocation: CLLocation? {
        manualLocationOverride ?? locationService.lastLocation
    }

    init(modelContext: ModelContext, vehicle: Vehicle?) {
        self.modelContext = modelContext
        self.selectedVehicle = vehicle
        self.fields.selectedFuelType = vehicle?.fuelType
    }

    // MARK: - Location capture (silent, automatic)

    func startLocationCapture() {
        locationService.start()
    }

    func stopLocationCapture() {
        locationService.stop()
    }

    /// Apply a user-picked coordinate from the map picker. Synthesises a
    /// `CLLocation` with invalid `horizontalAccuracy` (-1) so the row hides
    /// the accuracy label — a manually-placed pin has no meaningful accuracy.
    func applyManualLocation(_ coordinate: CLLocationCoordinate2D) {
        manualLocationOverride = CLLocation(
            coordinate: coordinate,
            altitude: 0,
            horizontalAccuracy: -1,
            verticalAccuracy: -1,
            timestamp: Date()
        )
    }

    /// Clear any manual override and force-acquire a fresh GPS fix at best
    /// accuracy. Wired to the refresh icon on the location row.
    func refreshLocation() {
        manualLocationOverride = nil
        locationService.refresh()
    }

    /// Fires the right cloud fetch automatically when the vehicle qualifies
    /// (Volvo + refresh token, or Toyota + configured API) and the user has
    /// not already typed an odometer value. Safe to call on every appear /
    /// vehicle change — the empty-text guard prevents stomping user input.
    func autoFetchOdometerIfNeeded() {
        guard fields.odometerText.isEmpty,
              let vehicle = selectedVehicle,
              vehicle.vin != nil else { return }

        switch vehicle.make?.lowercased() {
        case "volvo":
            guard KeychainService.load(for: KeychainService.volvoRefreshToken) != nil else { return }
            Task { await fetchVolvoOdometer() }
        case "toyota":
            guard ToyotaAPIConstants.isConfigured else { return }
            Task { await fetchToyotaOdometer() }
        default:
            return
        }
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

        if let effective = effectiveLocation {
            fields.location.apply(effective)
        }
        fields.location.writeTo(fillUp)

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
