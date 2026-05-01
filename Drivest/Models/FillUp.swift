import Foundation
import SwiftData

// MARK: - Currency conversion protocol

protocol CurrencyConvertible {
    var totalCost: Double { get }
    var currencyCode: String? { get }
    var exchangeRate: Double? { get }
}

extension CurrencyConvertible {
    func convertedCost(defaultCurrencyCode: String) -> Double? {
        guard let code = currencyCode,
              !code.isEmpty,
              code != defaultCurrencyCode,
              let rate = exchangeRate,
              rate > 0 else { return nil }
        return totalCost * rate
    }
    func costInDefaultCurrency(defaultCurrencyCode: String) -> Double {
        convertedCost(defaultCurrencyCode: defaultCurrencyCode) ?? totalCost
    }
}

// MARK: - FillUp model

@Model
final class FillUp {
    var id: UUID
    var date: Date
    var pricePerLiter: Double
    var volume: Double
    var totalCost: Double
    var odometerReading: Double
    var isFullTank: Bool
    var efficiency: Double?
    var note: String?
    var fuelType: FuelType?
    var createdAt: Date
    var currencyCode: String?
    var exchangeRate: Double?
    var discount: Double?
    var photoData: Data?
    var photos: [Data] = []

    var vehicle: Vehicle?

    init(
        date: Date = Date(),
        pricePerLiter: Double,
        volume: Double,
        totalCost: Double,
        odometerReading: Double,
        isFullTank: Bool = true,
        vehicle: Vehicle,
        note: String? = nil,
        fuelType: FuelType? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.pricePerLiter = pricePerLiter
        self.volume = volume
        self.totalCost = totalCost
        self.odometerReading = odometerReading
        self.isFullTank = isFullTank
        self.note = note
        self.fuelType = fuelType
        self.createdAt = Date()
        self.vehicle = vehicle
    }

    /// Legacy single photo + multi-photo array merged into one list.
    var allPhotos: [Data] {
        // On-read migration: move legacy photoData into photos array
        if let legacy = photoData {
            photoData = nil
            if !photos.contains(legacy) {
                photos.insert(legacy, at: 0)
            }
        }
        return photos
    }
}

// MARK: - Effective cost (after discount)

extension FillUp {
    /// Amount actually paid: gross total minus any discount.
    var effectiveCost: Double { max(0, totalCost - (discount ?? 0)) }
}

// MARK: - CurrencyConvertible conformance
// Override default implementation to use effectiveCost instead of totalCost.

extension FillUp: CurrencyConvertible {
    func convertedCost(defaultCurrencyCode: String) -> Double? {
        guard let code = currencyCode,
              !code.isEmpty,
              code != defaultCurrencyCode,
              let rate = exchangeRate,
              rate > 0 else { return nil }
        return effectiveCost * rate
    }
    func costInDefaultCurrency(defaultCurrencyCode: String) -> Double {
        convertedCost(defaultCurrencyCode: defaultCurrencyCode) ?? effectiveCost
    }
}

// MARK: - Predicate builder

extension FillUp {
    static func predicate(for vehicle: Vehicle) -> Predicate<FillUp> {
        let id = vehicle.id
        return #Predicate<FillUp> { $0.vehicle?.id == id }
    }
}
