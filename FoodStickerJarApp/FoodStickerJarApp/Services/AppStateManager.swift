import Foundation
import Combine

@MainActor
class AppStateManager: ObservableObject {
    /// The master switch for testing. This is automatically `true` for Debug
    /// builds and `false` for Release builds.
    private var forceShowOnboardingForTesting: Bool {
        #if DEBUG
        return false // Always show onboarding for developers
        #else
        return false // Never show onboarding for App Store users
        #endif
    }

    /// The shared singleton instance.
    static let shared = AppStateManager()

    /// A flag to indicate if the initial user state has been determined.
    /// The UI should wait for this to be true before showing the main view.
    @Published var isInitialized = false

    @Published var isOnboardingCompleted: Bool = false
    
    private let onboardingCompletedKey = "isOnboardingCompleted"
    
    private init() {
        if forceShowOnboardingForTesting {
            // If we are forcing the view, start with onboarding.
            self.isOnboardingCompleted = false
        }
    }
    
    func completeOnboarding() {
        if !forceShowOnboardingForTesting {
            UserDefaults.standard.set(true, forKey: onboardingCompletedKey)
        }
        // For the current session, always move to the home view after finishing.
        self.isOnboardingCompleted = true
    }
    
    func setOnboardingStatus(isCompleted: Bool) {
        if !forceShowOnboardingForTesting {
            self.isOnboardingCompleted = isCompleted
            UserDefaults.standard.set(isCompleted, forKey: onboardingCompletedKey)
        }
        
        // Once we have set the status from the remote source (or ignored it for testing),
        // the app is considered initialized.
        if !self.isInitialized {
            self.isInitialized = true
        }
    }
} 