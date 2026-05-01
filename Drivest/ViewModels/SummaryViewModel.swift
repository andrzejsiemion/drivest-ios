import Foundation
import SwiftData
import Observation

private let monthNameFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "LLLL yyyy"
    return f
}()

struct MonthlySummary: Identifiable {
    let id: String
    let year: Int
    let month: Int
    let totalCost: Double
    let totalVolume: Double
    let fillUpCount: Int
    let averageEfficiency: Double?

    var monthName: String {
        var components = DateComponents()
        components.year = year
        components.month = month
        let date = Calendar.current.date(from: components) ?? Date()
        return monthNameFormatter.string(from: date)
    }
}

struct PeriodStats {
    var totalCost: Double = 0
    var totalVolume: Double = 0
    var fillUpCount: Int = 0
    var averageEfficiency: Double? = nil
    var totalDistance: Double? = nil
    var averagePricePerLiter: Double? = nil

    var costPerKm: Double? {
        guard let dist = totalDistance, dist > 0 else { return nil }
        return totalCost / dist
    }

    var isEmpty: Bool { fillUpCount == 0 }
}

@Observable
final class SummaryViewModel {
    private let modelContext: ModelContext

    var lastMonth: PeriodStats = PeriodStats()
    var lastYear: PeriodStats = PeriodStats()
    var allTime: PeriodStats = PeriodStats()

    var chartPeriod: StatisticsTimePeriod = .allTime
    var chartType: ChartType = .odometer
    var chartPoints: [OdometerDataPoint] = []
    var currentPeriodStats: PeriodStats = PeriodStats()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func loadSummary(for vehicle: Vehicle?, defaultCurrencyCode: String = "") {
        guard let vehicle else {
            lastMonth = PeriodStats()
            lastYear = PeriodStats()
            allTime = PeriodStats()
            return
        }

        let descriptor = FetchDescriptor<FillUp>(
            predicate: FillUp.predicate(for: vehicle),
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let fillUps = (try? modelContext.fetch(descriptor)) ?? []

        let now = Date()
        let calendar = Calendar.current
        let monthStart = calendar.date(byAdding: .month, value: -1, to: calendar.startOfDay(for: now)) ?? now
        let yearStart = calendar.date(byAdding: .year, value: -1, to: calendar.startOfDay(for: now)) ?? now

        lastMonth = stats(from: fillUps.filter { $0.date >= monthStart }, defaultCurrencyCode: defaultCurrencyCode)
        lastYear = stats(from: fillUps.filter { $0.date >= yearStart }, defaultCurrencyCode: defaultCurrencyCode)
        allTime = stats(from: fillUps, defaultCurrencyCode: defaultCurrencyCode)
    }

    func loadChart(for vehicle: Vehicle?, defaultCurrencyCode: String = "") {
        guard let vehicle else {
            chartPoints = []
            currentPeriodStats = PeriodStats()
            return
        }

        let descriptor = FetchDescriptor<FillUp>(
            predicate: FillUp.predicate(for: vehicle),
            sortBy: [SortDescriptor(\.date, order: .forward), SortDescriptor(\.odometerReading, order: .forward)]
        )
        let allFillUps = (try? modelContext.fetch(descriptor)) ?? []

        let range = chartPeriod.dateRange
        let filtered = allFillUps.filter { fillUp in
            if let start = range.start, fillUp.date < start { return false }
            if let end = range.end, fillUp.date > end { return false }
            return true
        }

        let unit = vehicle.effectiveDistanceUnit
        chartPoints = filtered.compactMap { fillUp -> OdometerDataPoint? in
            let y: Double?
            switch chartType {
            case .odometer:
                y = unit == .miles ? fillUp.odometerReading / 1.60934 : fillUp.odometerReading
            case .efficiency:
                y = fillUp.efficiency
            case .fuelPrice:
                y = fillUp.pricePerLiter > 0 ? fillUp.pricePerLiter : nil
            case .costPerKm:
                guard let eff = fillUp.efficiency, eff > 0 else { return nil }
                y = fillUp.pricePerLiter * eff / 100.0
            }
            guard let value = y else { return nil }
            return OdometerDataPoint(date: fillUp.date, odometer: value)
        }
        currentPeriodStats = stats(from: filtered, defaultCurrencyCode: defaultCurrencyCode)
    }

    private func stats(from fillUps: [FillUp], defaultCurrencyCode: String) -> PeriodStats {
        guard !fillUps.isEmpty else { return PeriodStats() }
        let efficiencies = fillUps.compactMap(\.efficiency)
        let avgEff = efficiencies.isEmpty ? nil : efficiencies.reduce(0, +) / Double(efficiencies.count)
        let firstOdo = fillUps.first?.odometerReading
        let lastOdo = fillUps.last?.odometerReading
        let totalDistance: Double? = (firstOdo != nil && lastOdo != nil && lastOdo! > firstOdo!) ? lastOdo! - firstOdo! : nil
        let prices = fillUps.map(\.pricePerLiter).filter { $0 > 0 }
        let avgPrice: Double? = prices.isEmpty ? nil : prices.reduce(0, +) / Double(prices.count)
        return PeriodStats(
            totalCost: fillUps.reduce(0) { $0 + $1.costInDefaultCurrency(defaultCurrencyCode: defaultCurrencyCode) },
            totalVolume: fillUps.reduce(0) { $0 + $1.volume },
            fillUpCount: fillUps.count,
            averageEfficiency: avgEff,
            totalDistance: totalDistance,
            averagePricePerLiter: avgPrice
        )
    }
}
