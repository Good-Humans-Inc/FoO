import Foundation
import FirebaseAuth
import Combine
import RevenueCat

typealias FirebaseUser = FirebaseAuth.User

/// A service to manage the user's authentication state with Firebase.
/// This class listens for changes to the authentication state and provides the current user's info.
@MainActor
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
            guard let self = self else { return }
            
            Task {
                self.user = user
                
                if let user = user {
                    // Once we have a Firebase UID, log in to RevenueCat to alias the anonymous ID with it.
                    do {
                        print("[AuthService] Firebase user found (\(user.uid)). Logging into RevenueCat.")
                        let (customerInfo, created) = try await Purchases.shared.logIn(user.uid)
                        print("[AuthService] Successfully logged into RevenueCat. New user: \(created)")
                        
                        // Now that login/aliasing is complete, trigger a status refresh immediately.
                        print("[AuthService] Triggering a purchase status refresh after successful login.")
                        await PurchasesManager.shared.refreshStatus()
                        
                        // After everything is synced, mark the user session as ready.
                        self.appState.setUserSessionReady()
                        
                    } catch {
                        print("[AuthService] Error logging into RevenueCat: \(error.localizedDescription)")
                    }
                    
                    // If we have a user, sync their FCM token and check onboarding.
                    await self.syncFCMToken(for: user.uid)
                    await self.checkOnboardingStatus(for: user.uid)
                    
                } else {
                    // If there's no user, it means we need to sign in anonymously.
                    await self.signInAnonymously()
                }
            }
        }
    }
    
    /// Checks UserDefaults for a stored FCM token and syncs it to Firestore.
    /// This is a fallback for cases where the token is received before the initial auth state is confirmed.
    private func syncFCMToken(for userID: String) async {
        // Check if a token exists in UserDefaults
        if let token = UserDefaults.standard.string(forKey: "fcmToken") {
            print("-[FCM_DEBUG] Found pre-existing token in UserDefaults during auth. Syncing to Firestore for user \(userID)...")
            // Update the token in Firestore
            await firestoreService.updateUserFCMToken(for: userID, token: token)
        } else {
            // This is normal on first launch or if the token delegate hasn't fired yet.
            print("-[FCM_DEBUG] No pre-existing FCM token found in UserDefaults during auth. Will wait for delegate callback.")
        }
    }
    
    private func checkOnboardingStatus(for userID: String) async {
        do {
            // First, ensure a user document exists in the database.
            // This prevents errors for users created before this feature was added.
            await firestoreService.checkAndCreateUserDocument(for: userID)
            
            // Now, fetch the user profile. This should succeed now.
            let userProfile = try await firestoreService.fetchUser(with: userID)
            let isOnboardingCompleted = userProfile.onboardingCompleted ?? false
            
            // Update the app state and save the result to UserDefaults.
            self.appState.setOnboardingStatus(isCompleted: isOnboardingCompleted)
            
        } catch {
            // If the user document doesn't exist or another error occurs,
            // we assume they haven't completed onboarding.
            self.appState.setOnboardingStatus(isCompleted: false)
            // Even if onboarding fails to load, the session is ready to start.
            self.appState.setUserSessionReady()
            print("Could not fetch user profile to check onboarding status: \(error)")
        }
    }
    
    /// Signs the user in anonymously.
    /// This creates a temporary account on Firebase, allowing the user to use the app
    /// without providing credentials.
    private func signInAnonymously() async {
        do {
            let authResult = try await Auth.auth().signInAnonymously()
            let user = authResult.user
            print("Signed in anonymously with UID: \(user.uid)")
            // Ensure a user document exists in Firestore.
            await self.firestoreService.checkAndCreateUserDocument(for: user.uid)
        } catch {
            print("Error signing in anonymously: \(error.localizedDescription)")
        }
    }
    
    deinit {
        // When this object is deallocated, remove the listener to prevent memory leaks.
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
} 