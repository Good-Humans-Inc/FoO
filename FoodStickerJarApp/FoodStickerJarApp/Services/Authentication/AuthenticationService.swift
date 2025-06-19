import Foundation
import FirebaseAuth
import Combine

typealias FirebaseUser = FirebaseAuth.User

/// A service to manage the user's authentication state with Firebase.
/// This class listens for changes to the authentication state and provides the current user's info.
class AuthenticationService: ObservableObject {
    
    // A published property that holds the current Firebase User.
    // Your views can observe this to see if a user is signed in.
    @Published var user: FirebaseUser?
    
    // A handle for the authentication state listener, so we can detach it when the service is deallocated.
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let firestoreService = FirestoreService()
    
    init() {
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
            
            // If there's no user, it means we need to sign in anonymously.
            if user == nil {
                self?.signInAnonymously()
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