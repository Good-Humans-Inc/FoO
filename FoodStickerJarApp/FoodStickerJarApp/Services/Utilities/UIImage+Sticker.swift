import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

extension UIImage {
    /// Applies a "sticker" effect by adding an outline and filling any transparent "holes".
    /// The outline is a solid white color for normal stickers, and a pastel rainbow gradient for special ones.
    /// - Parameters:
    ///   - width: The desired width of the outline.
    ///   - isSpecial: Determines whether to apply the special rainbow effect.
    /// - Returns: A new `UIImage` with the sticker effect, or `nil` if processing fails.
    func addingStickerEffect(width: CGFloat, isSpecial: Bool) -> UIImage? {
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
        
        // --- Step 2: Use UIGraphicsImageRenderer for robust final compositing ---
        
        let finalSize = stickerShape.extent.size
        let renderer = UIGraphicsImageRenderer(size: finalSize)
        
        let finalImage = renderer.image { ctx in
            // --- Step 2a: Draw the correct background (solid white or rainbow) ---
            if isSpecial {
                // For special items, draw a pastel rainbow gradient.
                
                // Define the pastel colors based on the reference images.
                let pastelColors = [
                    UIColor(red: 1.00, green: 0.69, blue: 0.69, alpha: 1.0), // Light Pink/Red
                    UIColor(red: 1.00, green: 0.84, blue: 0.69, alpha: 1.0), // Light Orange
                    UIColor(red: 1.00, green: 1.00, blue: 0.69, alpha: 1.0), // Light Yellow
                    UIColor(red: 0.69, green: 1.00, blue: 0.84, alpha: 1.0), // Light Green/Mint
                    UIColor(red: 0.69, green: 0.84, blue: 1.00, alpha: 1.0), // Light Blue
                    UIColor(red: 0.84, green: 0.69, blue: 1.00, alpha: 1.0)  // Light Purple/Lavender
                ].map { $0.cgColor }

                // Create the gradient.
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                let gradient = CGGradient(colorsSpace: colorSpace, colors: pastelColors as CFArray, locations: nil)!

                // Render the CIImage of the sticker shape to a CGImage to use as a mask.
                guard let stickerMaskCgImage = context.createCGImage(stickerShape, from: stickerShape.extent) else { return }
                
                // Clip the drawing context to the shape of the sticker outline.
                ctx.cgContext.clip(to: CGRect(origin: .zero, size: finalSize), mask: stickerMaskCgImage)
                
                // Draw the gradient. We'll make it diagonal for a nice effect.
                ctx.cgContext.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: finalSize.width, y: finalSize.height), options: [])

            } else {
                // For normal items, use the original solid white outline method.
                let solidColor = CIImage(color: CIColor(color: .white))
                let stickerBaseCiImage = solidColor.applyingFilter("CIBlendWithMask", parameters: [
                    kCIInputMaskImageKey: stickerShape
                ])
                guard let stickerBaseCgImage = context.createCGImage(stickerBaseCiImage, from: stickerShape.extent) else { return }
                UIImage(cgImage: stickerBaseCgImage).draw(at: .zero)
            }
            
            // --- Step 2b: Draw the original image on top ---
            // This is offset by the border width to center it within the new, larger canvas.
            self.draw(at: CGPoint(x: width, y: width))
        }
        
        return finalImage
    }
}