import SwiftUI
import Combine

// This class manages the state and logic for the HomeView.
// @MainActor ensures that any changes to its @Published properties
// happen on the main thread, which is required for UI updates.
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties
    // These properties will trigger UI updates whenever they change.
    
    // The master list of all food items.
    @Published var foodItems: [FoodItem] = []
    
    // The currently selected item for viewing in the detail view.
    @Published var selectedFoodItem: FoodItem?
    
    // MARK: - Services and Engine
    
    // A single, persistent instance of the physics scene. This is crucial
    // to ensure the physics simulation doesn't reset every time the view updates.
    let jarScene = JarScene(size: .zero)
    
    // The service responsible for saving and loading data.
    private let persistenceService = PersistenceService()
    
    // Used to receive notifications from the JarScene when a sticker is tapped.
    private var cancellables = Set<AnyCancellable>()

    // A flag to ensure the scene is set up only once.
    private var hasSceneBeenSetUp = false

    // MARK: - Initializer
    
    init() {
        // Scene communication needs to be set up immediately.
        // The scene itself will be populated once its size is known from the view.
        setupJarSceneCommunication()
    }
    
    // MARK: - Public Methods
    
    /// Sets up the physics scene with the correct size and populates it with saved stickers.
    /// This should be called from the view once the layout is determined.
    /// - Parameter size: The size of the physics world.
    func setupScene(with size: CGSize) {
        // Ensure this setup only runs once and that the size is valid.
        guard !hasSceneBeenSetUp, size != .zero else { return }
        
        jarScene.size = size
        loadFoodItems() // Now this will populate a correctly-sized scene.
        hasSceneBeenSetUp = true
    }
    
    /// Adds a newly created sticker to the collection, saves it,
    /// and instructs the physics scene to animate it.
    /// - Parameter stickerImage: The final UIImage of the sticker (with outline).
    func addNewSticker(stickerImage: UIImage) {
        let newItem = FoodItem(image: stickerImage)
        foodItems.append(newItem)
        persistenceService.save(items: foodItems)
        
        // Instruct the JarScene to add the new sticker with a "falling" animation.
        jarScene.addSticker(item: newItem)
    }
    
    // MARK: - Private Methods
    
    /// Loads the saved food items from disk and populates the scene.
    private func loadFoodItems() {
        self.foodItems = persistenceService.load()
        // Pass the loaded items to the physics scene to populate the jar.
        jarScene.populateJar(with: self.foodItems)
    }
    
    /// Listens for tap events broadcasted from the JarScene.
    private func setupJarSceneCommunication() {
        jarScene.onStickerTapped
            .receive(on: DispatchQueue.main) // Ensure we switch to the main thread
            .sink { [weak self] tappedItemID in
                // Find the food item that corresponds to the tapped sticker's ID.
                self?.selectedFoodItem = self?.foodItems.first(where: { $0.id == tappedItemID })
            }
            .store(in: &cancellables)
    }
}