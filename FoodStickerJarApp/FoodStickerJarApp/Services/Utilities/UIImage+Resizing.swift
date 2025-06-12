import UIKit

extension UIImage {
    /// Resizes an image to a new size, preserving the aspect ratio.
    /// - Parameter maxSize: The maximum dimension (width or height) of the new image.
    /// - Returns: A new, resized `UIImage` instance.
    func resized(toMaxSize maxSize: CGFloat) -> UIImage {
        let originalSize = self.size
        let ratio = min(maxSize / originalSize.width, maxSize / originalSize.height)
        let newSize = CGSize(width: originalSize.width * ratio, height: originalSize.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
} 