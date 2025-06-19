import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    /// Creates an image of the background by removing the subject.
    /// - Parameters:
    ///   - originalImage: The full, original image.
    ///   - subjectImage: The image of the subject, with a transparent background.
    ///   - Returns: A new `UIImage` containing only the background, or `nil` on failure.
    static func createBackgroundMask(from originalImage: UIImage, subjectImage: UIImage) -> UIImage? {
        guard let originalCgImage = originalImage.cgImage,
              let subjectCgImage = subjectImage.cgImage else {
            return nil
        }
        
        let originalCiImage = CIImage(cgImage: originalCgImage)
        let subjectCiImage = CIImage(cgImage: subjectCgImage)
        
        // Use the "Source Out" compositing filter. This keeps the parts of the background
        // image (the original photo) that are NOT covered by the source image (the subject).
        // The result is the original with a subject-shaped hole.
        guard let compositeFilter = CIFilter(name: "CISourceOutCompositing") else {
            return nil
        }
        compositeFilter.setValue(subjectCiImage, forKey: kCIInputImageKey)
        compositeFilter.setValue(originalCiImage, forKey: kCIInputBackgroundImageKey)
        
        guard let outputCiImage = compositeFilter.outputImage else {
            return nil
        }
        
        let context = CIContext(options: nil)
        guard let outputCgImage = context.createCGImage(outputCiImage, from: outputCiImage.extent) else {
            return nil
        }
        
        return UIImage(cgImage: outputCgImage)
    }
} 