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
    
    // Holds the newly created sticker to be shown in the detail sheet
    // before it's added to the main jar.
    @Published var newSticker: FoodItem?
    
    // A private copy to hold the fully-analyzed sticker, avoiding a race condition
    // when the view is dismissed.
    private var stickerToCommit: FoodItem?
    
    // MARK: - Services and Engine
    
    // A single, persistent instance of the physics scene. This is crucial
    // to ensure the physics simulation doesn't reset every time the view updates.
    let jarScene = JarScene(size: .zero)
    
    // The service responsible for saving and loading data.
    private var persistenceService: PersistenceService?
    // The service for analyzing food images.
    private let analysisService = FoodAnalysisService()
    
    // Used to receive notifications from the JarScene when a sticker is tapped.
    private var cancellables = Set<AnyCancellable>()

    // A flag to ensure the scene is set up only once.
    private var hasSceneBeenSetUp = false

    // MARK: - Initializer
    
    init(authService: AuthenticationService) {
        // Scene communication needs to be set up immediately.
        // The scene itself will be populated once its size is known from the view.
        setupJarSceneCommunication()
        
        // Listen for the user to be authenticated.
        authService.$user
            .compactMap { $0?.uid } // We only care when we get a non-nil UID.
            .first() // We only need to do this setup once.
            .sink { [weak self] uid in
                guard let self = self else { return }
                
                print("User authenticated with UID: \(uid). Initializing persistence.")
                // Now that we have a UID, initialize the persistence service.
                self.persistenceService = PersistenceService(uid: uid)
                
                // If the scene is already set up, load the items.
                // Otherwise, the data will be loaded when setupScene is called.
                if self.hasSceneBeenSetUp {
                    self.loadFoodItems()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    /// Sets up the physics scene with the correct size and populates it with saved stickers.
    /// This should be called from the view once the layout is determined.
    /// - Parameter size: The size of the physics world.
    func setupScene(with size: CGSize) {
        // Ensure this setup only runs once and that the size is valid.
        guard !hasSceneBeenSetUp, size != .zero else { return }
        
        jarScene.size = size
        hasSceneBeenSetUp = true
        
        // If the persistence service is ready, load the data now.
        if persistenceService != nil {
            loadFoodItems()
        }
    }
    
    /// Creates a new `FoodItem` from an image, stores it temporarily,
    /// and kicks off the background analysis.
    /// - Parameter stickerImage: The final `UIImage` of the sticker.
    /// - Returns: The `FoodItem` that was created.
    @discardableResult
    func startStickerCreation(stickerImage: UIImage) -> FoodItem {
        let newItem = FoodItem(image: stickerImage)
        // Hold this new item temporarily to be shown in the sheet.
        self.newSticker = newItem
        self.stickerToCommit = newItem // Keep an initial copy
        
        // Kick off the background analysis.
        analyzeFoodItem(newItem)
        
        return newItem
    }
    
    /// Commits the temporarily held new sticker to the main collection,
    /// saves it, and adds it to the physics scene. This function is called
    /// by the view when the detail sheet is dismissed.
    func commitNewSticker() {
        // Use the private, safe-guarded copy of the sticker.
        guard let itemToAdd = stickerToCommit else { return }
        
        // 1. Add the sticker to the main data array.
        foodItems.append(itemToAdd)
        
        // 2. Save the updated array.
        persistenceService?.save(items: foodItems)
        
        // 3. Add the sticker to the physics scene, triggering the animation.
        jarScene.addSticker(item: itemToAdd)
        
        // 4. Clear the temporary item.
        stickerToCommit = nil
    }
    
    // MARK: - Private Methods
    
    /// Triggers the background analysis of a food item.
    /// When complete, it only updates the temporary `newSticker` property.
    private func analyzeFoodItem(_ item: FoodItem) {
        guard let image = item.image else { return }
        
        analysisService.analyzeFoodImage(image) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                var updatedItem = item
                
                switch result {
                case .success(let foodInfo):
                    updatedItem.name = foodInfo.name
                    updatedItem.funFact = foodInfo.funFact
                    updatedItem.nutrition = foodInfo.nutrition
                    
                case .failure(let error):
                    updatedItem.name = "N/A"
                    print("Food analysis failed for item \(item.id): \(error)")
                }

                // If this was the new sticker, update the temporary properties.
                if self.newSticker?.id == updatedItem.id {
                    self.newSticker = updatedItem
                    // Keep a private copy of the fully-updated item.
                    self.stickerToCommit = updatedItem
                }
            }
        }
    }
    
    /// Loads the saved food items from disk and populates the scene.
    private func loadFoodItems() {
        guard let persistenceService = persistenceService else {
            print("Cannot load items: persistence service not available.")
            return
        }
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