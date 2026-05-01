import SwiftUI

/// Embeddable form section for attaching a recurring cost reminder to a cost entry.
/// Receives a `DraftReminder?` binding — nil means no reminder is set.
struct ReminderFormSection: View {
    @Binding var draft: DraftReminder?
    let costEntryDate: Date
    let costEntryOdometer: Double?

    @State private var showIntervalPicker = false
    @State private var showLeadPicker = false

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

    @ViewBuilder
    private func timeFields(binding: Binding<DraftReminder>) -> some View {
        Button {
            showIntervalPicker = true
        } label: {
            HStack {
                Text(String(localized: "Every"))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(intervalSummary(binding.wrappedValue))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showIntervalPicker) {
            TimeIntervalPickerSheet(
                initialValue: binding.wrappedValue.intervalValue,
                initialUnit: binding.wrappedValue.intervalUnit,
                onDone: { value, unit in
                    binding.intervalValue.wrappedValue = value
                    binding.intervalUnit.wrappedValue = unit
                    applyLeadDefault(for: unit, currentLead: binding.wrappedValue.leadValue, binding: binding)
                    showIntervalPicker = false
                },
                onCancel: { showIntervalPicker = false }
            )
            .presentationDetents([.medium])
        }

        Button {
            showLeadPicker = true
        } label: {
            HStack {
                Text(String(localized: "Reminder"))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(leadSummaryTime(binding.wrappedValue.leadValue))
                    .foregroundStyle(.primary)
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .foregroundStyle(.primary)
        .sheet(isPresented: $showLeadPicker) {
            TimeLeadPickerSheet(
                initialValue: binding.wrappedValue.leadValue,
                onDone: { value in
                    binding.leadValue.wrappedValue = value
                    showLeadPicker = false
                },
                onCancel: { showLeadPicker = false }
            )
            .presentationDetents([.medium])
        }
    }

    // MARK: - Distance Fields

    @ViewBuilder
    private func distanceFields(binding: Binding<DraftReminder>) -> some View {
        if costEntryOdometer == nil {
            Text(String(localized: "No odometer data available. Add a fill-up first to use distance reminders."))
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            Button {
                showIntervalPicker = true
            } label: {
                HStack {
                    Text(String(localized: "Every"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(binding.wrappedValue.intervalValue) km")
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            .sheet(isPresented: $showIntervalPicker) {
                DistancePickerSheet(
                    initialValue: binding.wrappedValue.intervalValue,
                    presets: [5000, 10000, 15000, 20000, 30000],
                    title: String(localized: "Every"),
                    suffix: "km",
                    onDone: { value in
                        binding.intervalValue.wrappedValue = value
                        showIntervalPicker = false
                    },
                    onCancel: { showIntervalPicker = false }
                )
                .presentationDetents([.medium])
            }

            Button {
                showLeadPicker = true
            } label: {
                HStack {
                    Text(String(localized: "Reminder"))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(binding.wrappedValue.leadValue) km before")
                        .foregroundStyle(.primary)
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .foregroundStyle(.primary)
            .sheet(isPresented: $showLeadPicker) {
                DistancePickerSheet(
                    initialValue: binding.wrappedValue.leadValue,
                    presets: [100, 250, 500, 1000, 2000],
                    title: String(localized: "Reminder"),
                    suffix: String(localized: "km before"),
                    onDone: { value in
                        binding.leadValue.wrappedValue = value
                        showLeadPicker = false
                    },
                    onCancel: { showLeadPicker = false }
                )
                .presentationDetents([.medium])
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

// MARK: - Distance Picker Sheet

private struct DistancePickerSheet: View {
    let initialValue: Int
    let presets: [Int]
    let title: String
    let suffix: String
    let onDone: (Int) -> Void
    let onCancel: () -> Void

    @State private var localValue: Int
    @State private var customText: String

    init(initialValue: Int, presets: [Int], title: String, suffix: String,
         onDone: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.initialValue = initialValue
        self.presets = presets
        self.title = title
        self.suffix = suffix
        self.onDone = onDone
        self.onCancel = onCancel
        _localValue = State(initialValue: initialValue)
        _customText = State(initialValue: presets.contains(initialValue) ? "" : "\(initialValue)")
    }

    private var isPresetSelected: Bool { presets.contains(localValue) && customText.isEmpty }

    var body: some View {
        NavigationStack {
            List {
                Section(String(localized: "Quick Select")) {
                    ForEach(presets, id: \.self) { preset in
                        Button {
                            localValue = preset
                            customText = ""
                        } label: {
                            HStack {
                                Text("\(preset) \(suffix)")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if isPresetSelected && localValue == preset {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }

                Section(String(localized: "Custom")) {
                    HStack {
                        TextField("", text: $customText)
                            .keyboardType(.numberPad)
                            .onChange(of: customText) { _, newVal in
                                if let parsed = Int(newVal) { localValue = parsed }
                            }
                        Text(suffix)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(title)
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
