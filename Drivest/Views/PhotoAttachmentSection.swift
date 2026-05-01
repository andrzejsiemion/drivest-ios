import SwiftUI
import PhotosUI
import UIKit

struct PhotoAttachmentSection: View {
    @Binding var photos: [Data]

    @State private var showCamera = false
    @State private var selectedPhotoItem: PhotosPickerItem?

    var body: some View {
        Section("Photos") {
            ForEach(photos.indices, id: \.self) { index in
                if let image = UIImage(data: photos[index]) {
                    VStack(spacing: 6) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 180)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        Button("Remove", role: .destructive) {
                            photos.remove(at: index)
                        }
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label("Add from Library", systemImage: "photo.on.rectangle")
            }

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPickerView(isPresented: $showCamera) { image in
                if let image, let raw = image.jpegData(compressionQuality: 1.0),
                   let compressed = ImageCompressor.compress(raw) {
                    photos.append(compressed)
                }
            }
        }
        .onChange(of: selectedPhotoItem) {
            guard let item = selectedPhotoItem else { return }
            Task {
                if let raw = try? await item.loadTransferable(type: Data.self),
                   let compressed = ImageCompressor.compress(raw) {
                    photos.append(compressed)
                }
                selectedPhotoItem = nil
            }
        }
    }
}
