import SwiftUI

@MainActor
class JarDetailViewModel: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    
    let jarScene = JarScene(size: .zero)
    
    func setup(for jar: JarItem) {
        self.foodItems = jar.stickers
        self.jarScene.populateJar(with: jar.stickers)
    }
    
    func setupScene(with size: CGSize) {
        jarScene.size = size
        // Stickers are populated in setup(for:)
    }
} 