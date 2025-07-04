import Foundation
import FirebaseFirestore

/// Represents a user document in the Firestore database.
struct User: Codable, Identifiable {
    // The user's ID, which will match the document ID.
    @DocumentID var id: String?
    var fcmToken: String?
    
    // The list of IDs for all jars archived by this user.
    let jarIDs: [String]
    
    // The number of stickers created by this user.
    var stickerCount: Int?
    
    // MARK: - Onboarding Data
    var name: String?
    var age: Int?
    var pronoun: String?
    var goals: [String]?
    var onboardingCompleted: Bool?
    var timezone: String?
} 
