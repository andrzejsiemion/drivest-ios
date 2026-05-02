import SwiftUI

/// Embeddable form section for attaching a recurring cost reminder to a cost entry.
/// Receives a `DraftReminder?` binding — nil means no reminder is set.
struct ReminderFormSection: View {
    @Binding var draft: DraftReminder?
    let costEntryDate: Date
    let costEntryOdometer: Double?


    var body: some View {
        Section {
            Toggle(String(localized: "Set Reminder"), isOn: Binding(
                get: { draft != nil },
                set: { enabled in
                    draft = enabled ? .defaultTimeBased : nil
                }
            ))

            if let binding = Binding($draft) {
                reminderFields(binding: binding)
            }
        } header: {
            Text(String(localized: "Reminder"))
        }
    }

    @ViewBuilder
    private func reminderFields(binding: Binding<DraftReminder>) -> some View {
        Picker(String(localized: "Type"), selection: binding.type) {
            ForEach(ReminderType.allCases, id: \.self) { type in
                Text(type.displayName).tag(type)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: binding.wrappedValue.type) { _, newType in
            switch newType {
            case .timeBased:
                draft = .defaultTimeBased
            case .distanceBased:
                if costEntryOdometer != nil {
                    draft = .defaultDistanceBased
                } else {
                    draft?.type = .timeBased
                }
            }
        }

        if binding.wrappedValue.type == .timeBased {
            timeFields(binding: binding)
        } else {
            distanceFields(binding: binding)
        }
    }

    // MARK: - Time Fields

    private func intervalMax(for unit: ReminderIntervalUnit) -> Int {
        switch unit {
        case .days: return 365
        case .months: return 24
        case .years: return 10
        case .kilometers: return 1000
        }
    }

    @ViewBuilder
    private func timeFields(binding: Binding<DraftReminder>) -> some View {
        LabeledContent(String(localized: "Every")) {
            HStack(spacing: 0) {
                Picker("", selection: binding.intervalValue) {
                    ForEach(1...intervalMax(for: binding.wrappedValue.intervalUnit), id: \.self) { v in
                        Text("\(v)").tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .id(binding.wrappedValue.intervalUnit)

                Picker("", selection: binding.intervalUnit) {
                    Text(ReminderIntervalUnit.days.displayName).tag(ReminderIntervalUnit.days)
                    Text(ReminderIntervalUnit.months.displayName).tag(ReminderIntervalUnit.months)
                    Text(ReminderIntervalUnit.years.displayName).tag(ReminderIntervalUnit.years)
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .onChange(of: binding.wrappedValue.intervalUnit) { _, newUnit in
                    if binding.intervalValue.wrappedValue > intervalMax(for: newUnit) {
                        binding.intervalValue.wrappedValue = 1
                    }
                    applyLeadDefault(for: newUnit, currentLead: binding.wrappedValue.leadValue, binding: binding)
                }
            }
            .frame(height: 120)
        }

        LabeledContent(String(localized: "Reminder")) {
            HStack(spacing: 0) {
                Picker("", selection: binding.leadValue) {
                    ForEach(0...90, id: \.self) { v in
                        Text("\(v)").tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("", selection: Binding.constant(0)) {
                    Text(String(localized: "days before")).tag(0)
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .allowsHitTesting(false)
            }
            .frame(height: 120)
        }
    }

    // MARK: - Distance Fields

    private let intervalKmSteps: [Int] = Array(stride(from: 1000, through: 50000, by: 1000))
    private let leadKmSteps: [Int] = Array(stride(from: 100, through: 5000, by: 100))

    @ViewBuilder
    private func distanceFields(binding: Binding<DraftReminder>) -> some View {
        if costEntryOdometer == nil {
            Text(String(localized: "No odometer data available. Add a fill-up first to use distance reminders."))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            LabeledContent(String(localized: "Every")) {
                HStack(spacing: 0) {
                    Picker("", selection: binding.intervalValue) {
                        ForEach(intervalKmSteps, id: \.self) { v in
                            Text("\(v)").tag(v)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Picker("", selection: Binding.constant(0)) {
                        Text("km").tag(0)
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 80)
                    .clipped()
                    .allowsHitTesting(false)
                }
                .frame(height: 120)
            }

            LabeledContent(String(localized: "Reminder")) {
                HStack(spacing: 0) {
                    Picker("", selection: binding.leadValue) {
                        ForEach(leadKmSteps, id: \.self) { v in
                            Text("\(v)").tag(v)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: .infinity)
                    .clipped()

                    Picker("", selection: Binding.constant(0)) {
                        Text(String(localized: "km before")).tag(0)
                    }
                    .pickerStyle(.wheel)
                    .frame(maxWidth: 110)
                    .clipped()
                    .allowsHitTesting(false)
                }
                .frame(height: 120)
            }
        }
    }

    // MARK: - Helpers

    private func intervalSummary(_ draft: DraftReminder) -> String {
        "\(draft.intervalValue) \(draft.intervalUnit.displayName)"
    }

    private func leadSummaryTime(_ days: Int) -> String {
        if days == 0 { return String(localized: "On due date") }
        return "\(days) \(String(localized: "days before"))"
    }

    private func applyLeadDefault(for unit: ReminderIntervalUnit, currentLead: Int, binding: Binding<DraftReminder>) {
        let defaultLeads = [0, 1, 3, 7, 14, 30, 60, 90]
        guard defaultLeads.contains(currentLead) else { return }
        switch unit {
        case .years:  binding.leadValue.wrappedValue = 14
        case .months: binding.leadValue.wrappedValue = 7
        case .days:   binding.leadValue.wrappedValue = 1
        case .kilometers: break
        }
    }
}

// MARK: - Time Interval Picker Sheet

private struct TimeIntervalPickerSheet: View {
    let initialValue: Int
    let initialUnit: ReminderIntervalUnit
    let onDone: (Int, ReminderIntervalUnit) -> Void
    let onCancel: () -> Void

    @State private var localValue: Int
    @State private var localUnit: ReminderIntervalUnit

    init(initialValue: Int, initialUnit: ReminderIntervalUnit,
         onDone: @escaping (Int, ReminderIntervalUnit) -> Void,
         onCancel: @escaping () -> Void) {
        self.initialValue = initialValue
        self.initialUnit = initialUnit
        self.onDone = onDone
        self.onCancel = onCancel
        _localValue = State(initialValue: initialValue)
        _localUnit = State(initialValue: initialUnit)
    }

    private var maxValue: Int {
        switch localUnit {
        case .days: return 365
        case .months: return 24
        case .years: return 10
        case .kilometers: return 1000
        }
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("", selection: $localValue) {
                    ForEach(1...maxValue, id: \.self) { v in
                        Text("\(v)").tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .id(localUnit)

                Picker("", selection: $localUnit) {
                    Text(ReminderIntervalUnit.days.displayName).tag(ReminderIntervalUnit.days)
                    Text(ReminderIntervalUnit.months.displayName).tag(ReminderIntervalUnit.months)
                    Text(ReminderIntervalUnit.years.displayName).tag(ReminderIntervalUnit.years)
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .onChange(of: localUnit) { _, newUnit in
                    let max: Int
                    switch newUnit {
                    case .days: max = 365
                    case .months: max = 24
                    case .years: max = 10
                    case .kilometers: max = 1000
                    }
                    if localValue > max { localValue = 1 }
                }
            }
            .navigationTitle(String(localized: "Every"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { onDone(localValue, localUnit) }
                }
            }
        }
    }
}

// MARK: - Time Lead Picker Sheet

private struct TimeLeadPickerSheet: View {
    let initialValue: Int
    let onDone: (Int) -> Void
    let onCancel: () -> Void

    @State private var localValue: Int

    init(initialValue: Int, onDone: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.initialValue = initialValue
        self.onDone = onDone
        self.onCancel = onCancel
        _localValue = State(initialValue: max(initialValue, 0))
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("", selection: $localValue) {
                    ForEach(0...90, id: \.self) { v in
                        Text("\(v)").tag(v)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()

                Picker("", selection: Binding.constant(0)) {
                    Text(String(localized: "days before")).tag(0)
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .clipped()
                .allowsHitTesting(false)
            }
            .navigationTitle(String(localized: "Reminder"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { onDone(localValue) }
                }
            }
        }
    }
}

