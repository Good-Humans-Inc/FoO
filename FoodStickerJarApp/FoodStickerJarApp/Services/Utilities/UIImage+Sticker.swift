import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    /// Applies a "sticker" effect by adding a solid, opaque outline and filling any transparent "holes".
    /// This implementation uses a UIGraphicsImageRenderer for pixel-perfect layout to prevent clipping.
    /// - Parameters:
    ///   - width: The desired width of the outline.
    ///   - color: The color of the outline.
    /// - Returns: A new `UIImage` with the sticker effect, or `nil` if processing fails.
    func addingStickerOutline(width: CGFloat, color: UIColor) -> UIImage? {
        guard let originalCiImage = CIImage(image: self) else { return nil }
        let context = CIContext()

        // --- Step 1: Generate a hard, solid sticker base shape using Core Image ---

        // Get a grayscale representation of the image's alpha channel. Soft edges become gray.
        let alphaMask = originalCiImage.applyingFilter("CIMaskToAlpha")

        // Use a high-contrast filter to crush the gray, semi-transparent pixels into solid white.
        // This creates a hard-edged silhouette, preventing "holes" in the sticker.
        let contrastFilter = CIFilter.colorControls()
        contrastFilter.inputImage = alphaMask
        contrastFilter.contrast = 100.0 // Very high contrast to ensure hard edges.
        guard let hardSilhouette = contrastFilter.outputImage else { return nil }

        // Dilate the hard silhouette to create the larger sticker base shape.
        let morphologyFilter = CIFilter.morphologyMaximum()
        morphologyFilter.inputImage = hardSilhouette
        morphologyFilter.radius = Float(width)
        guard let stickerShape = morphologyFilter.outputImage else { return nil }
        
        // Color the sticker base shape with the desired solid color.
        let solidColor = CIImage(color: CIColor(color: color))
        let stickerBaseCiImage = solidColor.applyingFilter("CIBlendWithMask", parameters: [
            kCIInputMaskImageKey: stickerShape
        ])
        
        // --- Step 2: Use UIGraphicsImageRenderer for robust final compositing ---
        
        // The final canvas size needs to accommodate the original image plus the outline on all sides.
        let finalSize = CGSize(width: self.size.width + width * 2, height: self.size.height + width * 2)
        let renderer = UIGraphicsImageRenderer(size: finalSize)
        
        let finalImage = renderer.image { ctx in
            // First, render the CIImage of the sticker base to a CGImage.
            guard let stickerBaseCgImage = context.createCGImage(stickerBaseCiImage, from: stickerShape.extent) else { return }
            
            // Draw the sticker base at the origin of the renderer's context.
            let baseImage = UIImage(cgImage: stickerBaseCgImage)
            baseImage.draw(at: .zero)

            // Finally, draw the original image on top, centered.
            self.draw(at: CGPoint(x: width, y: width))
        }
        
        return finalImage
    }
}