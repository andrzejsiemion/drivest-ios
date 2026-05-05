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

    private var matchingReminder: Reminder? {
        costEntry.vehicle?.reminders.first(where: { $0.costEntryId == costEntry.id })
    }

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

            if let reminder = matchingReminder {
                Section(String(localized: "Reminder")) {
                    HStack {
                        Text(String(localized: "Type")).foregroundStyle(.secondary)
                        Spacer()
                        Label(
                            reminder.reminderType == .date
                                ? String(localized: "Date")
                                : String(localized: "Distance"),
                            systemImage: reminder.reminderType == .date
                                ? "calendar.badge.clock"
                                : "gauge.with.dots.needle.33percent"
                        )
                    }
                    if reminder.reminderType == .date, let dueDate = reminder.dueDate {
                        HStack {
                            Text(String(localized: "Due Date")).foregroundStyle(.secondary)
                            Spacer()
                            Text(dueDate, format: .dateTime.day().month(.wide).year())
                        }
                        HStack {
                            Text(String(localized: "Lead Time")).foregroundStyle(.secondary)
                            Spacer()
                            Text(String(localized: "\(reminder.leadDays) days before"))
                        }
                    }
                    if reminder.reminderType == .distance {
                        let unit = costEntry.vehicle?.effectiveDistanceUnit ?? .kilometers
                        if let target = reminder.targetOdometer {
                            HStack {
                                Text(String(localized: "Target Odometer")).foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.0f %@", unit.fromKm(target), unit.abbreviation))
                            }
                        }
                        if let lead = reminder.leadDistance {
                            HStack {
                                Text(String(localized: "Lead Distance")).foregroundStyle(.secondary)
                                Spacer()
                                Text(String(format: "%.0f %@", unit.fromKm(lead), unit.abbreviation))
                            }
                        }
                    }
                    HStack {
                        let status = ReminderEvaluationService.status(for: reminder, currentOdometer: costEntry.vehicle?.currentOdometer)
                        if reminder.reminderType == .date, let dueDate = reminder.dueDate {
                            Text(String(localized: "Time Left")).foregroundStyle(.secondary)
                            Spacer()
                            let days = Calendar.current.dateComponents([.day], from: Date(), to: dueDate).day ?? 0
                            Text("\(days) days")
                                .foregroundStyle(status == .overdue ? .red : status == .dueSoon ? .orange : .primary)
                        } else if reminder.reminderType == .distance, let target = reminder.targetOdometer {
                            let unit = costEntry.vehicle?.effectiveDistanceUnit ?? .kilometers
                            let currentKm = unit == .miles ? (costEntry.vehicle?.currentOdometer ?? 0) / 0.621371 : (costEntry.vehicle?.currentOdometer ?? 0)
                            let remaining = Int(unit.fromKm(target - currentKm))
                            Text(String(localized: "Distance Left")).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(remaining) \(unit.abbreviation)")
                                .foregroundStyle(status == .overdue ? .red : status == .dueSoon ? .orange : .primary)
                        }
                    }
                    HStack {
                        Text(String(localized: "Status")).foregroundStyle(.secondary)
                        Spacer()
                        ReminderStatusBadge(
                            status: ReminderEvaluationService.status(
                                for: reminder,
                                currentOdometer: costEntry.vehicle?.currentOdometer
                            )
                        )
                    }
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
        .alert("Delete Cost?", isPresented: $showDeleteConfirmation) {
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
