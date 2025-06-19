import Foundation
import FirebaseFirestore

/// Represents a jar document in the Firestore database.
struct JarItem: Codable, Identifiable {
    @DocumentID var id: String?
    let userID: String
    let timestamp: Timestamp
    let screenshotThumbnailURL: String
    let stickers: [FoodItem]
    // Optional report for the jar
    let report: String?
} 