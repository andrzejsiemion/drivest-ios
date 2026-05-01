import SwiftUI
import Charts

struct OdometerChartView: View {
    let points: [OdometerDataPoint]
    let unit: DistanceUnit
    @Binding var chartType: ChartType
    @Binding var period: StatisticsTimePeriod
    let hasFillUps: Bool

    @State private var showCustomPicker = false
    @State private var customStart: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var customEnd: Date = Date()

    var body: some View {
        VStack(spacing: 8) {
            chartTypePicker

            if points.isEmpty {
                emptyStateView
                    .frame(height: 220)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(yAxisLabel, point.odometer)
                    )
                    .foregroundStyle(Color.accentColor)
                    if points.count == 1 {
                        PointMark(
                            x: .value("Date", point.date),
                            y: .value(yAxisLabel, point.odometer)
                        )
                        .foregroundStyle(Color.accentColor)
                    }
                }
                .chartYScale(domain: yAxisDomain)
                .chartXScale(domain: xAxisDomain)
                .chartXAxis {
                    AxisMarks(values: xAxisValues) { _ in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: xAxisDateFormat)
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(yAxisFormat(v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .chartYAxisLabel(yAxisLabel, position: .leading)
                .frame(height: 220)
            }

            periodPicker
        }
        .sheet(isPresented: $showCustomPicker) {
            customDateSheet
        }
    }

    private var chartTypePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ChartType.allCases, id: \.self) { type in
                    pill(label: type.label, selected: chartType == type, font: .subheadline, hPad: 12, vPad: 6) {
                        chartType = type
                    }
                }
            }
            .padding(.horizontal, 16)
        }
        .mask(scrollFadeMask)
    }

    private var periodPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(StatisticsTimePeriod.chartCases, id: \.self) { p in
                    pill(label: p.chartLabel, selected: period == p, font: .subheadline, hPad: 12, vPad: 6) {
                        period = p
                    }
                }
                pill(label: String(localized: "Custom"), selected: period.isCustom, font: .subheadline, hPad: 12, vPad: 6) {
                    if case .custom(let s, let e) = period {
                        customStart = s
                        customEnd = e
                    }
                    showCustomPicker = true
                }
            }
            .padding(.horizontal, 16)
        }
        .mask(scrollFadeMask)
    }

    private var scrollFadeMask: some View {
        LinearGradient(
            stops: [
                .init(color: .clear, location: 0),
                .init(color: .black, location: 0.06),
                .init(color: .black, location: 0.94),
                .init(color: .clear, location: 1)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private func pill(label: String, selected: Bool, font: Font, hPad: CGFloat, vPad: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(font)
                .padding(.horizontal, hPad)
                .padding(.vertical, vPad)
                .background(selected ? Color.accentColor : Color(.secondarySystemFill))
                .foregroundStyle(selected ? Color.white : Color.primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var customDateSheet: some View {
        NavigationStack {
            Form {
                DatePicker(String(localized: "Start Date"), selection: $customStart, displayedComponents: .date)
                DatePicker(String(localized: "End Date"), selection: $customEnd, in: customStart..., displayedComponents: .date)
            }
            .navigationTitle(String(localized: "Custom Range"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Apply")) {
                        period = .custom(start: customStart, end: customEnd)
                        showCustomPicker = false
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) {
                        showCustomPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    @ViewBuilder
    private var emptyStateView: some View {
        if hasFillUps {
            VStack(spacing: 8) {
                Image(systemName: "chart.line.flattrend.xyaxis")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("No data for this period.")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "bolt.car")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Add fill-ups to see odometer progress.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var yAxisLabel: String {
        switch chartType {
        case .odometer:   unit.abbreviation
        case .efficiency: "L/100km"
        case .fuelPrice:  String(localized: "Price/L")
        case .costPerKm:  String(localized: "Cost/km")
        }
    }

    private func yAxisFormat(_ v: Double) -> String {
        switch chartType {
        case .odometer:
            return v >= 1000 ? "\(Int(v / 1000))k" : "\(Int(v))"
        case .efficiency, .fuelPrice, .costPerKm:
            return String(format: "%.2f", v)
        }
    }

    private var yAxisDomain: ClosedRange<Double> {
        guard let minVal = points.map(\.odometer).min(),
              let maxVal = points.map(\.odometer).max(),
              minVal < maxVal else {
            return (points.first?.odometer ?? 0)...(points.first?.odometer ?? 1)
        }
        let padding = (maxVal - minVal) * 0.10
        return (minVal - padding)...(maxVal + padding)
    }

    private var xAxisValues: [Date] {
        guard let first = points.first?.date, let last = points.last?.date, first < last else {
            return [points.first?.date].compactMap { $0 }
        }
        let span = last.timeIntervalSince(first)
        return [first, first.addingTimeInterval(span / 3), first.addingTimeInterval(span * 2 / 3), last]
    }

    private var xAxisDomain: ClosedRange<Date> {
        guard let first = points.first?.date, let last = points.last?.date, first < last else {
            return (points.first?.date ?? Date())...(points.last?.date ?? Date())
        }
        let padding = last.timeIntervalSince(first) * 0.20
        return first...(last.addingTimeInterval(padding))
    }

    private var xAxisDateFormat: Date.FormatStyle {
        guard let first = points.first?.date, let last = points.last?.date, first < last else {
            return .dateTime.month().year()
        }
        let days = Calendar.current.dateComponents([.day], from: first, to: last).day ?? 0
        return days < 90 ? .dateTime.day().month() : .dateTime.month().year(.twoDigits)
    }
}
