import SwiftUI

@main
struct FoodStickerJarApp: App {
    // Create a single instance of the ViewModel that will be used for the lifetime of the app.
    @StateObject private var homeViewModel = HomeViewModel()

    var body: some Scene {
        WindowGroup {
            HomeView()
                // Provide the ViewModel to the HomeView and its descendants.
                .environmentObject(homeViewModel)
        }
    }
}
