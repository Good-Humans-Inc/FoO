import Foundation
import UIKit

// Represents a single food sticker.
// Codable: Allows us to encode/decode it to/from JSON for local storage.
// Identifiable: Lets SwiftUI know how to uniquely identify each item in a list.
// Equatable: Helps in finding and comparing items.
// Hashable: Allows the item to be used as a unique identifier for the view.
struct FoodItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let creationDate: Date
    
    // The image data is no longer stored directly in the document.
    // Instead, we store the URLs pointing to the images in Firebase Storage.
    var imageURLString: String
    var thumbnailURLString: String
    var originalImageURLString: String?
    
    // Properties for food analysis data from the backend.
    // They are optional because they will be populated asynchronously.
    var isFood: Bool?
    var name: String?
    var funFact: String?
    
    // A flag to determine if the item has special, rare content.
    var isSpecial: Bool?
}
