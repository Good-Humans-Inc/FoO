import SwiftUI
import Combine

@MainActor
class JarDetailViewModel: ObservableObject {
    @Published var foodItems: [FoodItem] = []
    @Published var selectedFoodItem: FoodItem?
    
    let jarScene = JarScene(size: .zero)
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupJarSceneCommunication()
    }
    
    func setup(for jar: JarItem) {
        // Use nil-coalescing to handle old jars that don't have the stickers field.
        let stickers = jar.stickers ?? []
        self.foodItems = stickers
        self.jarScene.populateJar(with: stickers)
    }
    
    func setupScene(with size: CGSize) {
        jarScene.size = size
        // Stickers are populated in setup(for:)
    }
    
    private func setupJarSceneCommunication() {
        jarScene.onStickerTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tappedItemID in
                self?.selectedFoodItem = self?.foodItems.first(where: { $0.id == tappedItemID })
            }
            .store(in: &cancellables)
    }
} 