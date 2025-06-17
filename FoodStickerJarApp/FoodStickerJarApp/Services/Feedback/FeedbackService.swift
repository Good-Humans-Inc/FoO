import Foundation

/// A service dedicated to handling user feedback submissions.
final class FeedbackService {
    
    /// Submits a feedback message from the user.
    ///
    /// For this initial implementation, the feedback is simply printed to the console.
    /// This can be replaced with a network call to a backend service like Firestore
    /// in the future without changing the call site.
    ///
    /// - Parameter message: The feedback string to be submitted.
    func submitFeedback(message: String) {
        // In a real application, you would send this to your backend.
        // For example, creating a new document in a "feedback" collection in Firestore.
        print("--- User Feedback ---")
        print(message)
        print("---------------------")
    }
} 