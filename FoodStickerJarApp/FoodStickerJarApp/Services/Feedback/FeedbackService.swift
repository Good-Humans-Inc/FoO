import Foundation
import FirebaseAuth
import FirebaseFirestore

/// A service dedicated to handling user feedback submissions.
final class FeedbackService {
    
    // A reference to the Firestore database.
    private let db = Firestore.firestore()
    
    /// Submits a feedback message from the user to the Firestore database.
    ///
    /// - Parameter message: The feedback string to be submitted.
    func submitFeedback(message: String) {
        // Ensure a user is signed in to get a userID.
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: Cannot submit feedback without a logged-in user.")
            return
        }
        
        // Create a new Feedback object. The timestamp will be set by the server.
        let feedback = Feedback(userID: userID, message: message)
        
        do {
            // Create a new document in the "feedback" collection from our model.
            try db.collection("feedback").addDocument(from: feedback)
            print("Feedback submitted successfully!")
        } catch {
            print("Error submitting feedback to Firestore: \(error.localizedDescription)")
        }
    }
} 
