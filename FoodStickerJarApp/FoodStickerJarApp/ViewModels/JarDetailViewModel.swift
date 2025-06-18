import SwiftUI

@MainActor
class JarDetailViewModel: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let jarScene = JarScene(size: .zero)
    private let firestoreService = FirestoreService()
    
    func fetchStickers(for jar: JarItem, in userID: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let items = try await firestoreService.fetchStickers(by: jar.stickerIDs, for: userID)
                self.foodItems = items
                self.isLoading = false
                self.jarScene.populateJar(with: items)
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to load stickers: \(error.localizedDescription)"
            }
        }
    }
    
    func setupScene(with size: CGSize) {
        jarScene.size = size
        // Stickers are populated after fetching
    }
} 