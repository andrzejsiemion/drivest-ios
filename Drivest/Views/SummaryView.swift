import SwiftUI
import SwiftData

struct SummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    @State private var viewModel: SummaryViewModel?

    let vehicle: Vehicle?

    private var defaultSymbol: String? { CurrencyDefinition.symbol(for: defaultCurrencyCode) }

    private func costText(_ value: Double) -> String {
        if let symbol = defaultSymbol {
            return String(format: "%.2f %@", value, symbol)
        }
        return String(format: "%.2f", value)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let vm = viewModel {
                    if vm.allTime.isEmpty {
                        EmptyStateView(
                            title: "No Data",
                            message: "Add fill-ups to see your expense summary.",
                            actionLabel: "Done"
                        ) { dismiss() }
                    } else {
                        List {
                            periodSection(title: "Last Month", stats: vm.lastMonth)
                            periodSection(title: "Last Year", stats: vm.lastYear)
                            periodSection(title: "All Time", stats: vm.allTime)
                        }
                    }
                }
            }
            .navigationTitle("Statistics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if viewModel == nil {
                    viewModel = SummaryViewModel(modelContext: modelContext)
                }
                viewModel?.loadSummary(for: vehicle, defaultCurrencyCode: defaultCurrencyCode)
            }
        }
    }

    @ViewBuilder
    private func periodSection(title: LocalizedStringKey, stats: PeriodStats) -> some View {
        Section(header: Text(title)) {
            if stats.isEmpty {
                Text("No fill-ups in this period").foregroundStyle(.secondary)
            } else {
                LabeledContent("Total Spent") {
                    Text(costText(stats.totalCost)).fontWeight(.semibold)
                }
                LabeledContent("Total Fuel") {
                    Text(String(format: "%.2f L", stats.totalVolume))
                }
                LabeledContent("Fill-Ups") {
                    Text("\(stats.fillUpCount)")
                }
                if stats.averageEfficiency != nil {
                    LabeledContent("Avg Efficiency") {
                        Text(EfficiencyCalculator.formatEfficiency(stats.averageEfficiency, for: vehicle))
                    }
                }
            }
        }
    }
}
