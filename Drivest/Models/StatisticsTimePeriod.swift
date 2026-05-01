import Foundation

enum ChartType: Equatable, Hashable, CaseIterable {
    case odometer
    case efficiency
    case fuelPrice
    case costPerKm

    var label: String {
        switch self {
        case .odometer:   String(localized: "Mileage")
        case .efficiency: String(localized: "Efficiency")
        case .fuelPrice:  String(localized: "Fuel Price")
        case .costPerKm:  String(localized: "Cost/km")
        }
    }
}

enum StatisticsTimePeriod: Equatable, Hashable {
    case allTime
    case yearToDate
    case previousYear
    case thisMonth
    case previousMonth
    case custom(start: Date, end: Date)

    var dateRange: (start: Date?, end: Date?) {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        switch self {
        case .allTime:
            return (nil, nil)
        case .yearToDate:
            let start = calendar.date(from: DateComponents(year: calendar.component(.year, from: now), month: 1, day: 1))
            return (start, nil)
        case .previousYear:
            let prevYear = calendar.component(.year, from: now) - 1
            let start = calendar.date(from: DateComponents(year: prevYear, month: 1, day: 1))
            let end = calendar.date(from: DateComponents(year: prevYear, month: 12, day: 31))
                .flatMap { calendar.date(bySettingHour: 23, minute: 59, second: 59, of: $0) }
            return (start, end)
        case .thisMonth:
            let start = calendar.date(from: calendar.dateComponents([.year, .month], from: today))
            return (start, nil)
        case .previousMonth:
            let firstOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: today))!
            let firstOfPrevMonth = calendar.date(byAdding: .month, value: -1, to: firstOfThisMonth)
            let lastOfPrevMonth = calendar.date(byAdding: .day, value: -1, to: firstOfThisMonth)
                .flatMap { calendar.date(bySettingHour: 23, minute: 59, second: 59, of: $0) }
            return (firstOfPrevMonth, lastOfPrevMonth)
        case .custom(let start, let end):
            let orderedStart = min(start, end)
            let orderedEnd = max(start, end)
            return (calendar.startOfDay(for: orderedStart), orderedEnd)
        }
    }

    var displayName: String {
        switch self {
        case .allTime: "All Time"
        case .yearToDate: "Year to Date"
        case .previousYear: "Previous Year"
        case .thisMonth: "This Month"
        case .previousMonth: "Previous Month"
        case .custom: "Custom"
        }
    }

    var chartLabel: String {
        switch self {
        case .allTime: String(localized: "All")
        case .yearToDate: String(localized: "YTD")
        case .previousYear: String(localized: "Prev Y")
        case .thisMonth: String(localized: "This M")
        case .previousMonth: String(localized: "Prev M")
        case .custom: String(localized: "Custom")
        }
    }

    static var chartCases: [StatisticsTimePeriod] {
        [.allTime, .yearToDate, .previousYear, .thisMonth, .previousMonth]
    }

    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
}
