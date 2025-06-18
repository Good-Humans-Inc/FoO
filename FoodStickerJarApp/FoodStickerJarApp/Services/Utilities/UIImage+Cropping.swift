import UIKit

extension UIImage {
    /// Crops the image to the bounding box of its non-transparent pixels.
    /// - Returns: A new, cropped `UIImage`, or the original image if cropping fails or is unnecessary.
    func croppedToOpaque() -> UIImage? {
        guard let cgImage = self.cgImage else { return self }
        
        // Get the dimensions of the image.
        let width = cgImage.width
        let height = cgImage.height
        
        // The color space and bitmap info are crucial for creating a context.
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        // Allocate memory for the pixel data.
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
              let data = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return self
        }
        
        // Draw the image to the context to access its pixel data.
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        // Find the bounding box of the non-transparent pixels.
        var minX = width
        var minY = height
        var maxX = 0
        var maxY = 0
        
        // Iterate over every pixel to find the bounds.
        for y in 0..<height {
            for x in 0..<width {
                let alpha = data[(y * bytesPerRow) + (x * bytesPerPixel) + 3]
                if alpha > 0 {
                    minX = min(minX, x)
                    minY = min(minY, y)
                    maxX = max(maxX, x)
                    maxY = max(maxY, y)
                }
            }
        }
        
        // If the image is entirely transparent, return a blank image.
        guard minX <= maxX, minY <= maxY else { return UIImage() }
        
        // Create the cropping rectangle.
        let cropRect = CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)
        
        // Crop the original CGImage and create a new UIImage from it.
        guard let croppedCgImage = cgImage.cropping(to: cropRect) else { return self }
        
        return UIImage(cgImage: croppedCgImage, scale: self.scale, orientation: self.imageOrientation)
    }
} 