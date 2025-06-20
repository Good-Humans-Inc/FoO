import Foundation
import FirebaseAuth
import Combine

typealias FirebaseUser = FirebaseAuth.User

/// A service to manage the user's authentication state with Firebase.
/// This class listens for changes to the authentication state and provides the current user's info.
class AuthenticationService: ObservableObject {
    /// The shared singleton instance.
    static let shared = AuthenticationService()
    
    // A published property that holds the current Firebase User.
    // Your views can observe this to see if a user is signed in.
    @Published var user: FirebaseUser?
    
    // A handle for the authentication state listener, so we can detach it when the service is deallocated.
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let firestoreService = FirestoreService()
    
    // A reference to the AppStateManager to update the app's flow.
    private let appState = AppStateManager.shared
    
    private init() {
        // When the service is created, start listening for authentication changes.
        addAuthStateListener()
    }
    
    /// Listens for real-time changes to the user's sign-in state.
    /// This is the recommended way to get the current user.
    private func addAuthStateListener() {
        // The listener gets called whenever a user signs in or out.
        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            // Update the published user property.
            self?.user = user
            
            if let user = user {
                // If we have a user, sync their FCM token and check onboarding.
                self?.syncFCMToken(for: user.uid)
                self?.syncUserSession(for: user.uid)
            } else {
                // If there's no user, it means we need to sign in anonymously.
                self?.signInAnonymously()
            }
        }
    }
    
    /// Checks UserDefaults for a stored FCM token and syncs it to Firestore.
    /// This is a fallback for cases where the token is received before the initial auth state is confirmed.
    private func syncFCMToken(for userID: String) {
        // Check if a token exists in UserDefaults
        if let token = UserDefaults.standard.string(forKey: "fcmToken") {
            print("-[FCM_DEBUG] Found pre-existing token in UserDefaults during auth. Syncing to Firestore for user \(userID)...")
            Task {
                // Update the token in Firestore
                await firestoreService.updateUserFCMToken(for: userID, token: token)
            }
        } else {
            // This is normal on first launch or if the token delegate hasn't fired yet.
            print("-[FCM_DEBUG] No pre-existing FCM token found in UserDefaults during auth. Will wait for delegate callback.")
        }
    }
    
    private func syncUserSession(for userID: String) {
        Task {
            do {
                // First, ensure a user document exists in the database.
                // This prevents errors for users created before this feature was added.
                await firestoreService.checkAndCreateUserDocument(for: userID)
                
                // Now, fetch the user profile. This should succeed now.
                let userProfile = try await firestoreService.fetchUser(with: userID)
                let isOnboardingCompleted = userProfile.onboardingCompleted ?? false
                let freeCapturesLeft = userProfile.freeCapturesLeft ?? 0
                let hasPremium = userProfile.hasPremium ?? false
                
                // Update the app state and save the result to UserDefaults.
                await MainActor.run {
                    self.appState.setUserData(
                        onboardingCompleted: isOnboardingCompleted,
                        freeCaptures: freeCapturesLeft,
                        hasPremium: hasPremium
                    )
                }
            } catch {
                // If the user document doesn't exist or another error occurs,
                // we assume they haven't completed onboarding.
                await MainActor.run {
                    self.appState.setUserData(
                        onboardingCompleted: false,
                        freeCaptures: 0,
                        hasPremium: false
                    )
                }
                print("Could not fetch user profile to check onboarding status: \(error)")
            }
        }
    }
    
    /// Signs the user in anonymously.
    /// This creates a temporary account on Firebase, allowing the user to use the app
    /// without providing credentials.
    private func signInAnonymously() {
        Auth.auth().signInAnonymously { (authResult, error) in
            if let error = error {
                print("Error signing in anonymously: \(error.localizedDescription)")
                return
            }
            
            if let user = authResult?.user {
                print("Signed in anonymously with UID: \(user.uid)")
                // Ensure a user document exists in Firestore.
                Task {
                    await self.firestoreService.checkAndCreateUserDocument(for: user.uid)
                }
            }
        }
    }
    
    deinit {
        // When this object is deallocated, remove the listener to prevent memory leaks.
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
} 