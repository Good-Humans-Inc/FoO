import Foundation
import UIKit
import FirebaseFirestore

// Represents a single food sticker.
// Codable: Allows us to encode/decode it to/from JSON for local storage and Firestore.
// Identifiable: Lets SwiftUI know how to uniquely identify each item in a list.
// Equatable: Helps in finding and comparing items.
// Hashable: Allows the item to be used as a unique identifier for the view.
struct FoodItem: Identifiable, Codable, Equatable, Hashable {
    // By adding @DocumentID, Firestore automatically populates this property
    // with the document's ID when data is fetched.
    @DocumentID var id: String?
    
    let creationDate: Date
    let imageData: Data
    let thumbnailData: Data
    
    // Properties for food analysis data from the backend.
    // They are optional because they will be populated asynchronously.
    var name: String?
    var funFact: String?
    var nutrition: String?

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
        // The ID will be nil until the item is saved to Firestore.
        self.id = nil
        self.creationDate = Date()
        
        // We store the image as PNG data for persistence.
        self.imageData = image.pngData() ?? Data()
        
        // Create and store a smaller thumbnail for efficient loading in the jar.
        let thumbnail = image.resized(toMaxSize: 150) // 150px is a good size for the jar
        self.thumbnailData = thumbnail.pngData() ?? Data()
        
        // The analysis properties start as nil.
        self.name = nil
        self.funFact = nil
        self.nutrition = nil
    }
}
