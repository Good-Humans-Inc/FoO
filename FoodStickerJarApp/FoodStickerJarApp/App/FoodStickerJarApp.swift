import SwiftUI
import Firebase

@main
struct FoodStickerJarApp: App {
    // Connect the AppDelegate to the SwiftUI app lifecycle.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // We can still use @StateObject to make sure SwiftUI manages the lifecycle
    // of our singleton instances.
    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var appState = AppStateManager.shared
    @StateObject private var navigationRouter = NavigationRouter()

    // Environment variable to track the app's scene phase.
    @Environment(\.scenePhase) private var scenePhase

    init() {
        // Initialize PurchasesManager
        _ = PurchasesManager.shared
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
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
                        .environmentObject(HomeViewModel(authService: authService, navigationRouter: navigationRouter))
                        .environmentObject(appState)
                } else {
                    // Show a loading view while Firebase is authenticating the user.
                    ProgressView()
                }
            }
            .fullScreenCover(item: $navigationRouter.selectedFoodItem) { foodItem in
                // The router now controls this presentation
                FoodDetailView(foodItem: .constant(foodItem))
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // When the app becomes active, clear the badge.
                UIApplication.shared.applicationIconBadgeNumber = 0
                print("-[FCM_DEBUG] Scene became active. Cleared application badge number via scenePhase.")
            }
        }
    }
}
  
