import Foundation
import FirebaseFirestore

/// A data model representing a single piece of user feedback.
struct Feedback: Codable, Identifiable {
    /// The document ID, managed by Firestore.
    @DocumentID var id: String?
    
    /// The ID of the user who submitted the feedback.
    let userID: String
    
    /// The content of the feedback message.
    let message: String
    
    /// The timestamp when the feedback was submitted.
    @ServerTimestamp var timestamp: Timestamp?
} 
