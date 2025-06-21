import Foundation
import FirebaseAuth

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
    @Published var pronoun: String = ""
    @Published var goals: [String] = []
    
    private let firestoreService = FirestoreService()
    private let userProfileService = UserProfileService()
    
    func completeOnboarding() async throws {
        // Ensure we have a currently authenticated user.
        guard let userID = Auth.auth().currentUser?.uid else {
            // This should not happen if the user is in the onboarding flow.
            throw NSError(domain: "AuthError", code: 0, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }
        
        try await firestoreService.completeOnboarding(
            for: userID,
            name: name,
            age: age,
            pronoun: pronoun,
            goals: goals
        )
        
        // After successfully saving to Firestore, also save the profile locally.
        let localProfile = UserProfile(name: name, age: age, pronoun: pronoun, goals: goals)
        userProfileService.saveProfile(localProfile)
    }
} 