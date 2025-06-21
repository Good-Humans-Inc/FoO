import SwiftUI

@main
struct FoodStickerJarApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var navigationRouter = NavigationRouter()

    var body: some Scene {
        WindowGroup {
            if appState.isUserSignedIn {
                HomeView()
                    .environmentObject(HomeViewModel(authService: authService, navigationRouter: navigationRouter))
                    .environmentObject(appState)
                    .environmentObject(navigationRouter)
            } else {
                ProgressView()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // ... existing code ...
            }
        }
    }
} 