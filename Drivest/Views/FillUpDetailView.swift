import SwiftUI
import SwiftData

struct FillUpDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    let fillUp: FillUp
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var cachedImages: [Int: UIImage] = [:]

    private var currencySymbol: String? { CurrencyDefinition.symbol(for: fillUp.currencyCode ?? defaultCurrencyCode) }
    private var convertedCost: Double? { fillUp.convertedCost(defaultCurrencyCode: defaultCurrencyCode) }
    private var defaultSymbol: String? { CurrencyDefinition.symbol(for: defaultCurrencyCode) }

    var body: some View {
        List {
            Section {
                if let vehicle = fillUp.vehicle {
                    LabeledContent("Vehicle", value: vehicle.name)
                }
                LabeledContent("Date") {
                    Text(fillUp.date, format: .dateTime.day().month(.wide).year().hour().minute())
                }
                LabeledContent("Odometer") {
                    Text(String(format: "%.0f km", fillUp.odometerReading))
                }
            }

            Section("Fuel") {
                if let fuelType = fillUp.fuelType {
                    LabeledContent("Fuel Type", value: fuelType.displayName)
                }
                LabeledContent("Price per Unit") {
                    if let symbol = currencySymbol {
                        Text(String(format: "%.2f %@/L", fillUp.pricePerLiter, symbol))
                    } else {
                        Text(String(format: "%.2f", fillUp.pricePerLiter))
                    }
                }
                LabeledContent("Volume") {
                    Text(String(format: "%.2f L", fillUp.volume))
                }
                LabeledContent("Total Cost") {
                    HStack(spacing: 6) {
                        if let converted = convertedCost, let symbol = defaultSymbol {
                            Text(String(format: "≈ %.2f %@", converted, symbol))
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        if let symbol = currencySymbol {
                            Text(String(format: "%.2f %@", fillUp.effectiveCost, symbol))
                                .fontWeight(.semibold)
                        } else {
                            Text(String(format: "%.2f", fillUp.effectiveCost))
                                .fontWeight(.semibold)
                        }
                    }
                }
            }

            Section("Details") {
                if let discount = fillUp.discount, discount > 0 {
                    LabeledContent("Discount") {
                        if let symbol = currencySymbol {
                            Text(String(format: "%.2f %@", discount, symbol))
                        } else {
                            Text(String(format: "%.2f", discount))
                        }
                    }
                }
                LabeledContent("Full Tank") {
                    Text(fillUp.isFullTank ? "Yes" : "No")
                }
                if let efficiency = fillUp.efficiency {
                    LabeledContent("Efficiency") {
                        Text(String(format: "%.1f L/100km", efficiency))
                    }
                }
            }

            if let note = fillUp.note, !note.isEmpty {
                Section("Note") {
                    Text(note)
                }
            }

            if !fillUp.allPhotos.isEmpty {
                Section("Photos") {
                    ForEach(fillUp.allPhotos.indices, id: \.self) { index in
                        if let image = cachedImages[index] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        } else {
                            Image(systemName: "photo.badge.exclamationmark")
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Fill-Up")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            for (index, data) in fillUp.allPhotos.enumerated() {
                if cachedImages[index] == nil {
                    cachedImages[index] = UIImage(data: data)
                }
            }
        }
        .navigationTitle("Fill-Up Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditFillUpView(fillUp: fillUp, modelContext: modelContext)
        }
        .confirmationDialog("Delete Fill-Up?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                deleteFillUp()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private func deleteFillUp() {
        let vehicle = fillUp.vehicle
        modelContext.delete(fillUp)
        if let vehicle {
            let vehicleId = vehicle.id
            let descriptor = FetchDescriptor<FillUp>(
                predicate: #Predicate<FillUp> { f in f.vehicle?.id == vehicleId },
                sortBy: [SortDescriptor(\.date)]
            )
            let remaining = (try? modelContext.fetch(descriptor)) ?? []
            EfficiencyCalculator.recalculateAll(for: vehicle, allFillUps: remaining)
        }
        Persistence.save(modelContext)
        dismiss()
    }
}
