import Foundation

// MARK: - AdditionalCurrency

struct AdditionalCurrency: Codable, Identifiable, Equatable {
    var code: String
    var rate: Double   // 1 unit of this currency = `rate` units of default currency
    var rateSource: RateSource
    var rateUpdatedAt: Date?
    var id: String { code }

    enum RateSource: String, Codable { case nbp, manual }

    init(code: String, rate: Double, rateSource: RateSource = .nbp, rateUpdatedAt: Date? = nil) {
        self.code = code
        self.rate = rate
        self.rateSource = rateSource
        self.rateUpdatedAt = rateUpdatedAt
    }

    // Migration: old entries had no rateSource/rateUpdatedAt → default to .manual
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        code = try c.decode(String.self, forKey: .code)
        rate = try c.decode(Double.self, forKey: .rate)
        rateSource = (try? c.decode(RateSource.self, forKey: .rateSource)) ?? .manual
        rateUpdatedAt = try? c.decode(Date.self, forKey: .rateUpdatedAt)
    }
}

// MARK: - AppPreferences

struct AppPreferences {
    static var defaultCurrency: String {
        get { UserDefaults.standard.string(forKey: "defaultCurrency") ?? "" }
        set { UserDefaults.standard.set(newValue, forKey: "defaultCurrency") }
    }
    static var additionalCurrencies: [AdditionalCurrency] {
        get {
            if let data = UserDefaults.standard.data(forKey: "additionalCurrencies"),
               let decoded = try? JSONDecoder().decode([AdditionalCurrency].self, from: data) {
                return decoded
            }
            // Migrate from old single-secondary setup
            let old = UserDefaults.standard.string(forKey: "secondaryCurrency") ?? ""
            let rate = UserDefaults.standard.double(forKey: "exchangeRate")
            if !old.isEmpty {
                return [AdditionalCurrency(code: old, rate: rate > 0 ? rate : 1.0)]
            }
            return []
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "additionalCurrencies")
            }
        }
    }
    static func rate(for code: String) -> Double {
        additionalCurrencies.first { $0.code == code }?.rate ?? 1.0
    }

    static var nbpLastFetchDate: Date? {
        get { UserDefaults.standard.object(forKey: "nbpLastFetchDate") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "nbpLastFetchDate") }
    }

    /// Apply fetched rates (code → mid vs PLN) respecting per-currency source flags.
    /// `defaultMidPLN` is 1.0 when the default currency is PLN; otherwise the mid of the default currency.
    static func applyNBPRates(_ rates: [String: Double], defaultMidPLN: Double, fetchDate: Date) {
        var currencies = additionalCurrencies
        for i in currencies.indices {
            guard currencies[i].rateSource == .nbp else { continue }
            if let mid = rates[currencies[i].code] {
                currencies[i].rate = mid / defaultMidPLN
                currencies[i].rateUpdatedAt = fetchDate
            }
        }
        additionalCurrencies = currencies
        nbpLastFetchDate = Date()
    }

    static var vehicleSortOrder: VehicleSortOrder {
        get { VehicleSortOrder(rawValue: UserDefaults.standard.string(forKey: "vehicleSortOrder") ?? "") ?? .lastUsed }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: "vehicleSortOrder") }
    }
    static var customVehicleOrder: [String] {
        get { UserDefaults.standard.stringArray(forKey: "customVehicleOrder") ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: "customVehicleOrder") }
    }
}
