import SwiftUI

struct VehiclePhotoView: View {
    let photoData: Data?
    var size: CGFloat = 44

    var body: some View {
        if let photoData, let uiImage = UIImage(data: photoData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: size, height: size)
                .clipShape(Circle())
                .accessibilityLabel("Vehicle photo")
        } else {
            Image(systemName: "fuelpump.fill")
                .font(.system(size: size * 0.4))
                .foregroundStyle(.secondary)
                .frame(width: size, height: size)
                .background(Color(.systemGray5))
                .clipShape(Circle())
                .accessibilityLabel("No vehicle photo")
        }
    }
}
