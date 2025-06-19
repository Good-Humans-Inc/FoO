import SwiftUI

@main
struct FoodStickerJarApp: App {
    // Connect the AppDelegate to the SwiftUI app lifecycle.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // We can still use @StateObject to make sure SwiftUI manages the lifecycle
    // of our singleton instances.
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var appState = AppStateManager.shared

    var body: some Scene {
        WindowGroup {
            if !appState.isInitialized {
                // While the app is fetching the user's state, show our custom loading view.
                LaunchLoadingView()
            } else if !appState.isOnboardingCompleted {
                OnboardingView {
                    // This closure is called by the OnboardingView when it's done.
                    appState.completeOnboarding()
                }
            } else if authService.user != nil {
                // We create the HomeViewModel here, only after we know the user is signed in.
                // This ensures that all services are initialized in the correct order.
                HomeView()
                    .environmentObject(HomeViewModel(authService: authService))
            } else {
                // Show a loading view while Firebase is authenticating the user.
                ProgressView()
            }
        }
    }
}
  
