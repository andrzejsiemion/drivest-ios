import SwiftUI

private enum LeadUnit: String, CaseIterable {
    case days
    case months

    var localizedName: String {
        switch self {
        case .days: String(localized: "days")
        case .months: String(localized: "months")
        }
    }
}

struct DaysPickerRow: View {
    let label: String
    @Binding var value: Int

    @State private var isExpanded = false
    @State private var useKeyboard = false
    @State private var textValue = ""
    @State private var pickerNumber: Int = 14
    @State private var pickerUnit: LeadUnit = .days
    @State private var didInit = false
    @FocusState private var isTextFieldFocused: Bool

    private var displayText: String {
        if pickerUnit == .months {
            let months = value / 30
            return "\(months) \(LeadUnit.months.localizedName)"
        }
        return "\(value) \(LeadUnit.days.localizedName)"
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(displayText)
                    .foregroundStyle(.primary)
                Image(systemName: useKeyboard ? "dial.low" : "keyboard")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .onTapGesture {
                        if useKeyboard {
                            if let parsed = Int(textValue), parsed >= 0 {
                                value = parsed
                                syncFromValue()
                            }
                            isTextFieldFocused = false
                        } else {
                            textValue = "\(value)"
                        }
                        useKeyboard.toggle()
                        if !isExpanded { isExpanded = true }
                    }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation { isExpanded.toggle() }
            }

            if isExpanded {
                if useKeyboard {
                    HStack {
                        TextField("\(value)", text: $textValue)
                            .keyboardType(.numberPad)
                            .focused($isTextFieldFocused)
                            .font(.title3)
                            .multilineTextAlignment(.center)
                            .onAppear { textValue = "\(value)" }
                            .onChange(of: textValue) {
                                if let parsed = Int(textValue), parsed >= 0 {
                                    value = parsed
                                    syncFromValue()
                                }
                            }
                        Text(String(localized: "days"))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    .onAppear { isTextFieldFocused = true }
                } else {
                    HStack(spacing: 0) {
                        Picker("", selection: $pickerNumber) {
                            ForEach(0...50, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()

                        Picker("", selection: $pickerUnit) {
                            ForEach(LeadUnit.allCases, id: \.self) { unit in
                                Text(unit.localizedName).tag(unit)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(maxWidth: .infinity)
                        .clipped()
                    }
                    .frame(height: 150)
                }
            }
        }
        .onAppear {
            guard !didInit else { return }
            didInit = true
            syncFromValue()
        }
        .onChange(of: pickerNumber) { _ , _ in
            DispatchQueue.main.async { updateValue() }
        }
        .onChange(of: pickerUnit) { _, _ in
            DispatchQueue.main.async { updateValue() }
        }
    }

    private func updateValue() {
        let days = pickerUnit == .months ? pickerNumber * 30 : pickerNumber
        value = days
    }

    private func syncFromValue() {
        if value >= 30 && value % 30 == 0 {
            pickerUnit = .months
            pickerNumber = value / 30
        } else {
            pickerUnit = .days
            pickerNumber = min(value, 50)
        }
    }
}
