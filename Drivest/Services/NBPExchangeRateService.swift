import Foundation
import Observation

@Observable
final class NBPExchangeRateService {
    var isFetching = false
    var fetchError: String? = nil

    private let refreshInterval: TimeInterval = 4 * 3600  // 4 hours

    var needsRefresh: Bool {
        guard let last = AppPreferences.nbpLastFetchDate else { return true }
        return Date().timeIntervalSince(last) > refreshInterval
    }

    func fetchIfNeeded() async {
        guard needsRefresh, !isFetching else { return }
        await fetch()
    }

    func fetch() async {
        guard !isFetching else { return }
        isFetching = true
        fetchError = nil
        defer { isFetching = false }
        do {
            let (rates, fetchDate) = try await fetchTableA()
            let defaultCode = AppPreferences.defaultCurrency
            let defaultMidPLN = defaultCode == "PLN" || defaultCode.isEmpty ? 1.0 : (rates[defaultCode] ?? 1.0)
            AppPreferences.applyNBPRates(rates, defaultMidPLN: defaultMidPLN, fetchDate: fetchDate)
        } catch {
            fetchError = "Could not update rates. Using last known values."
        }
    }

    // MARK: - Network

    private struct NBPTable: Decodable {
        struct RateEntry: Decodable { let code: String; let mid: Double }
        let effectiveDate: String
        let rates: [RateEntry]
    }

    private func fetchTableA() async throws -> ([String: Double], Date) {
        let url = URL(string: "https://api.nbp.pl/api/exchangerates/tables/A/?format=json")!
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        let tables = try JSONDecoder().decode([NBPTable].self, from: data)
        guard let table = tables.first else { throw URLError(.badServerResponse) }

        let ratesDict = Dictionary(uniqueKeysWithValues: table.rates.map { ($0.code, $0.mid) })

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(identifier: "Europe/Warsaw")
        let fetchDate = formatter.date(from: table.effectiveDate) ?? Date()

        return (ratesDict, fetchDate)
    }
}
