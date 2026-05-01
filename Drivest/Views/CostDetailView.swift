import SwiftUI
import SwiftData

struct CostDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage("defaultCurrency") private var defaultCurrencyCode: String = ""
    let costEntry: CostEntry
    @Environment(\.dismiss) private var dismiss
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var cachedImages: [Int: UIImage] = [:]

    private var currencySymbol: String? { CurrencyDefinition.symbol(for: costEntry.currencyCode ?? defaultCurrencyCode) }
    private var convertedAmount: Double? { costEntry.convertedAmount(defaultCurrencyCode: defaultCurrencyCode) }
    private var defaultSymbol: String? { CurrencyDefinition.symbol(for: defaultCurrencyCode) }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("Date").foregroundStyle(.secondary)
                    Spacer()
                    Text(costEntry.date, format: .dateTime.day().month(.wide).year())
                }
                HStack {
                    Text("Category").foregroundStyle(.secondary)
                    Spacer()
                    Label(LocalizedStringKey(costEntry.categoryName), systemImage: costEntry.categoryIcon)
                }
                HStack {
                    Text("Amount")
                    Spacer()
                    if let converted = convertedAmount, let symbol = defaultSymbol {
                        Text(String(format: "≈ %.2f %@", converted, symbol))
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                    if let symbol = currencySymbol {
                        Text(String(format: "%.2f %@", costEntry.amount, symbol))
                            .fontWeight(.semibold)
                    } else {
                        Text(String(format: "%.2f", costEntry.amount))
                            .fontWeight(.semibold)
                    }
                }
            }

            if let note = costEntry.note, !note.isEmpty {
                Section("Note") {
                    Text(note)
                }
            }

            if !costEntry.allPhotos.isEmpty {
                Section("Photos") {
                    ForEach(costEntry.allPhotos.indices, id: \.self) { index in
                        if let image = cachedImages[index] {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 280)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }
            }

            if !costEntry.attachmentNames.isEmpty {
                Section("Documents") {
                    ForEach(costEntry.attachmentNames.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: costEntry.attachmentNames[index].attachmentIconName)
                                .foregroundStyle(.secondary)
                            Text(costEntry.attachmentNames[index])
                                .lineLimit(1)
                            Spacer()
                            ShareLink(
                                item: costEntry.attachmentData[index],
                                preview: SharePreview(costEntry.attachmentNames[index])
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Text("Delete Cost")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .onAppear {
            for (index, data) in costEntry.allPhotos.enumerated() {
                if cachedImages[index] == nil {
                    cachedImages[index] = UIImage(data: data)
                }
            }
        }
        .navigationTitle("Cost Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    showEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditCostView(costEntry: costEntry)
        }
        .confirmationDialog("Delete Cost?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                modelContext.delete(costEntry)
                Persistence.save(modelContext)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}
