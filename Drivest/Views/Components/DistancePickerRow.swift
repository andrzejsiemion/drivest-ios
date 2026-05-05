import SwiftUI

struct DistancePickerRow: View {
    let label: String
    let unit: String
    @Binding var value: Int

    @State private var isExpanded = false
    @State private var useKeyboard = false
    @State private var textValue = ""
    @State private var pickerThousands: Int = 0
    @State private var pickerHundreds: Int = 0
    @State private var didInit = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value) \(unit)")
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
                                }
                            }
                        Text(unit)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    .onAppear { isTextFieldFocused = true }
                } else {
                    HStack(spacing: 0) {
                        Picker("", selection: $pickerThousands) {
                            ForEach(0...100, id: \.self) { n in
                                Text("\(n)").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()

                        Text(",")
                            .font(.title2)
                            .foregroundStyle(.secondary)

                        Picker("", selection: $pickerHundreds) {
                            ForEach(0..<10, id: \.self) { n in
                                Text("\(n)00").tag(n)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(width: 80)
                        .clipped()

                        Text(unit)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)
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
        .onChange(of: pickerThousands) { _, _ in
            DispatchQueue.main.async { updateValue() }
        }
        .onChange(of: pickerHundreds) { _, _ in
            DispatchQueue.main.async { updateValue() }
        }
    }

    private func updateValue() {
        value = pickerThousands * 1000 + pickerHundreds * 100
    }

    private func syncFromValue() {
        pickerThousands = value / 1000
        pickerHundreds = (value % 1000) / 100
    }
}
