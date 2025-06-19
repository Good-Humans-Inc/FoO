import Foundation
import Combine

@MainActor
class AppStateManager: ObservableObject {
    /// The shared singleton instance.
    static let shared = AppStateManager()

    /// A flag to indicate if the initial user state has been determined.
    /// The UI should wait for this to be true before showing the main view.
    @Published var isInitialized = false

    @Published var isOnboardingCompleted: Bool = false
    
    private let onboardingCompletedKey = "isOnboardingCompleted"
    
    private init() {
        // We no longer read from UserDefaults here, as we need to wait for the
        // remote state to be fetched to avoid race conditions.
    }
    
    func completeOnboarding() {
        self.isOnboardingCompleted = true
        UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
    }
    
    func setOnboardingStatus(isCompleted: Bool) {
        self.isOnboardingCompleted = isCompleted
        UserDefaults.standard.set(isCompleted, forKey: onboardingCompletedKey)
        
        // Once we have set the status from the remote source, the app is initialized.
        if !self.isInitialized {
            self.isInitialized = true
        }
    }
} 