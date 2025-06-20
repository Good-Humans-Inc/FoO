import Foundation
import Combine

@MainActor
class AppStateManager: ObservableObject {
    /// The master switch for testing. This is automatically `true` for Debug
    /// builds and `false` for Release builds.
    private var forceShowOnboardingForTesting: Bool {
        #if DEBUG
        return true // Always show onboarding for developers
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
    @Published var isSubscribed: Bool = false
    @Published var freeCapturesLeft: Int = 0
    @Published var showPaywall: Bool = false
    
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
    
    func setUserData(onboardingCompleted: Bool, freeCaptures: Int, hasPremium: Bool) {
        if !forceShowOnboardingForTesting {
            self.isOnboardingCompleted = onboardingCompleted
            UserDefaults.standard.set(onboardingCompleted, forKey: onboardingCompletedKey)
        }
        self.freeCapturesLeft = freeCaptures
        self.isSubscribed = hasPremium
        
        // Once we have set the status from the remote source (or ignored it for testing),
        // the app is considered initialized.
        if !self.isInitialized {
            self.isInitialized = true
        }
    }

    func decrementFreeCaptures() {
        if freeCapturesLeft > 0 {
            freeCapturesLeft -= 1
            
            guard let userID = AuthenticationService.shared.user?.uid else { return }
            Task {
                await FirestoreService().decrementFreeCaptures(for: userID)
            }
        }
    }

    func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching customer info: \(error.localizedDescription)")
                return
            }
            
            if customerInfo?.entitlements.all["premium"]?.isActive == true {
                self.isSubscribed = true
            } else {
                self.isSubscribed = false
            }
        }
    }
} 