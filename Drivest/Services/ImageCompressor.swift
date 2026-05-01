import UIKit

struct ImageCompressor {
    private static let maxDimension: CGFloat = 300
    private static let jpegQuality: CGFloat = 0.7
    private static let maxBytes = 500_000

    /// Resizes image to max 300×300 and compresses to JPEG ≤500KB.
    static func compress(_ imageData: Data) -> Data? {
        guard let image = UIImage(data: imageData) else { return nil }
        let resized = resizeImage(image, maxDimension: maxDimension)
        guard let compressed = resized.jpegData(compressionQuality: jpegQuality) else { return nil }

        if compressed.count <= maxBytes {
            return compressed
        }

        // If still too large, reduce quality further
        var quality: CGFloat = 0.5
        while quality > 0.1 {
            if let data = resized.jpegData(compressionQuality: quality), data.count <= maxBytes {
                return data
            }
            quality -= 0.1
        }

        return resized.jpegData(compressionQuality: 0.1)
    }

    private static func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
