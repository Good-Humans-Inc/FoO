import SwiftUI

@main
struct FoodStickerJarApp: App {
    // Connect the AppDelegate to the SwiftUI app lifecycle.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    // Create a single, shared instance of the AuthenticationService.
    @StateObject private var authService = AuthenticationService()
    
    var body: some Scene {
        WindowGroup {
            // We show a loading view until the user is authenticated.
            if authService.user != nil {
                // We create the HomeViewModel here, only after we know the user is signed in.
                // This ensures that all services are initialized in the correct order.
                HomeView()
                    .environmentObject(HomeViewModel(authService: authService))
            } else {
                ProgressView()
            }
        }
    }
}
  
