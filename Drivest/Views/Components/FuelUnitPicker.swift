import SwiftUI

struct FuelUnitPicker: View {
    let fuelType: FuelType?
    @Binding var selectedUnit: FuelUnit?

    private var availableUnits: [FuelUnit] {
        guard let fuelType else {
            return FuelUnit.allCases
        }
        return fuelType.compatibleFuelUnits
    }

    var body: some View {
        Picker("Fuel Unit", selection: $selectedUnit) {
            Text("Not set").tag(FuelUnit?.none)
            ForEach(availableUnits, id: \.self) { unit in
                Text(LocalizedStringKey(unit.displayName)).tag(FuelUnit?.some(unit))
            }
        }
    }
}
