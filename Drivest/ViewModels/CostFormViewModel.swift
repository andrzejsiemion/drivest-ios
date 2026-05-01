import Foundation
import SwiftData
import Observation

/// Shared state for AddCostViewModel and EditCostViewModel.
@Observable
class CostFormViewModel {
    let modelContext: ModelContext

    var date: Date = Date()
    var amountText: String = ""
    var noteText: String = ""
    var selectedPhotos: [Data] = []
    var selectedAttachmentData: [Data] = []
    var selectedAttachmentNames: [String] = []
    var exchangeRateText: String = ""

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var amount: Double? { amountText.parseDouble() }
    /// Exchange rate, or nil if the parsed value is zero or missing (guards against division by zero).
    var exchangeRate: Double? {
        guard let rate = exchangeRateText.parseDouble(), rate > 0 else { return nil }
        return rate
    }
}
