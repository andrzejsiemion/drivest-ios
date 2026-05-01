import Foundation
import SwiftData

@Model
final class CostEntry {
    var id: UUID
    var date: Date
    var categoryName: String
    var categoryIcon: String
    var amount: Double
    var note: String?
    var createdAt: Date
    var vehicle: Vehicle?
    var currencyCode: String?
    var exchangeRate: Double?
    var photoData: Data?
    var photos: [Data] = []
    var attachmentData: [Data] = []
    var attachmentNames: [String] = []

    @Relationship(deleteRule: .cascade)
    var reminder: CostReminder?

    /// Legacy single photo + multi-photo array merged into one list.
    var allPhotos: [Data] { ([photoData].compactMap { $0 }) + photos }

    init(
        date: Date = Date(),
        categoryName: String,
        categoryIcon: String,
        amount: Double,
        note: String? = nil
    ) {
        self.id = UUID()
        self.date = date
        self.categoryName = categoryName
        self.categoryIcon = categoryIcon
        self.amount = amount
        self.note = note
        self.createdAt = Date()
    }

    /// Returns amount converted to the default currency, or nil if already in default currency.
    func convertedAmount(defaultCurrencyCode: String) -> Double? {
        guard let code = currencyCode,
              !code.isEmpty,
              code != defaultCurrencyCode,
              let rate = exchangeRate,
              rate > 0 else { return nil }
        return amount * rate
    }

    /// Returns amount in the default currency (applying conversion if needed).
    func amountInDefaultCurrency(defaultCurrencyCode: String) -> Double {
        convertedAmount(defaultCurrencyCode: defaultCurrencyCode) ?? amount
    }
}

// MARK: - Predicate builder

extension CostEntry {
    static func predicate(for vehicle: Vehicle) -> Predicate<CostEntry> {
        let id = vehicle.id
        return #Predicate<CostEntry> { $0.vehicle?.id == id }
    }
}
