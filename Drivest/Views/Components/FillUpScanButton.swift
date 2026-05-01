import SwiftUI

/// ReceiptScanButton pre-wired to a FillUpFormViewModel.
/// Applies detected values and triggers auto-calculation.
struct FillUpScanButton: View {
    let viewModel: FillUpFormViewModel

    var body: some View {
        ReceiptScanButton { price, volume, total, image in
            if let price  { viewModel.pricePerLiterText = price }
            if let volume { viewModel.volumeText        = volume }
            if let total  { viewModel.totalCostText     = total }
            if let image, let raw = image.jpegData(compressionQuality: 1.0) {
                Task {
                    if let compressed = ImageCompressor.compress(raw) {
                        viewModel.selectedPhotos.append(compressed)
                    }
                }
            }
            // Trigger auto-calculation for whichever two fields were set
            let setCount = [price, volume, total].compactMap { $0 }.count
            if setCount == 2 {
                if price != nil && volume != nil {
                    viewModel.onFieldEdited(.pricePerLiter); viewModel.onFieldEdited(.volume)
                } else if price != nil && total != nil {
                    viewModel.onFieldEdited(.pricePerLiter); viewModel.onFieldEdited(.totalCost)
                } else {
                    viewModel.onFieldEdited(.volume); viewModel.onFieldEdited(.totalCost)
                }
            }
        }
    }
}
