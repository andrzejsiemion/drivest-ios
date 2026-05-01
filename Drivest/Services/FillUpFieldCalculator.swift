import Foundation

enum FillUpField {
    case pricePerLiter, volume, totalCost
}

enum FillUpFieldCalculator {
    static func autoCalculate(
        lastEditedFields: (first: FillUpField, second: FillUpField),
        pricePerLiter: Double?,
        volume: Double?,
        totalCost: Double?
    ) -> (field: FillUpField, value: String)? {
        let computedField: FillUpField
        switch (lastEditedFields.first, lastEditedFields.second) {
        case (.pricePerLiter, .volume), (.volume, .pricePerLiter):
            computedField = .totalCost
        case (.pricePerLiter, .totalCost), (.totalCost, .pricePerLiter):
            computedField = .volume
        case (.volume, .totalCost), (.totalCost, .volume):
            computedField = .pricePerLiter
        default:
            computedField = .totalCost
        }

        switch computedField {
        case .totalCost:
            if let p = pricePerLiter, let v = volume, p > 0, v > 0 {
                return (.totalCost, String(format: "%.2f", p * v))
            }
        case .volume:
            if let p = pricePerLiter, let t = totalCost, p > 0 {
                return (.volume, String(format: "%.2f", t / p))
            }
        case .pricePerLiter:
            if let v = volume, let t = totalCost, v > 0 {
                return (.pricePerLiter, String(format: "%.3f", t / v))
            }
        }
        return nil
    }
}
