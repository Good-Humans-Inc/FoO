import Foundation
import UIKit

// Represents a single food sticker.
// Codable: Allows us to encode/decode it to/from JSON for local storage.
// Identifiable: Lets SwiftUI know how to uniquely identify each item in a list.
// Equatable: Helps in finding and comparing items.
struct FoodItem: Identifiable, Codable, Equatable {
    let id: UUID
    let imageData: Data
    let thumbnailData: Data

    // Computed property to easily get a UIImage from the stored data.
    var image: UIImage? {
        UIImage(data: imageData)
    }
    
    // Computed property for the smaller thumbnail image.
    var thumbnailImage: UIImage? {
        UIImage(data: thumbnailData)
    }

    // A convenience initializer to create a FoodItem directly from a UIImage.
    init(image: UIImage) {
        self.id = UUID()
        // We store the image as PNG data for persistence.
        self.imageData = image.pngData() ?? Data()
        
        // Create and store a smaller thumbnail for efficient loading in the jar.
        let thumbnail = image.resized(toMaxSize: 150) // 150px is a good size for the jar
        self.thumbnailData = thumbnail.pngData() ?? Data()
    }
}
