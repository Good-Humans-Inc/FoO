import Foundation

/// A struct that models the JSON response from the food analysis Cloud Function.
struct FoodInfo: Codable, Hashable {
    let name: String
    let funFact: String
    let nutrition: String
    
    // Maps the Swift property names to the JSON keys from the backend.
    enum CodingKeys: String, CodingKey {
        case name
        case funFact = "fun_fact"
        case nutrition
    }
} 