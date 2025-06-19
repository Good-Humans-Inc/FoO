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
    
    // State properties for managing the sticker creation UI flow.
    @Published var isSavingSticker = false
    @Published var stickerCreationError: String?
    
    // MARK: - Services and Engine
    
    // A single, persistent instance of the physics scene. This is crucial
    // to ensure the physics simulation doesn't reset every time the view updates.
    let jarScene = JarScene(size: .zero)
    
    // The service responsible for saving and loading data from Firestore.
    private let firestoreService = FirestoreService()
    // The service for analyzing food images.
    private let analysisService = FoodAnalysisService()
    
    // Used to receive notifications from the JarScene when a sticker is tapped.
    private var cancellables = Set<AnyCancellable>()

    // The authenticated user's ID, captured on login.
    private var userId: String?
    
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
                
                print("HomeViewModel: User authenticated with UID: \(uid).")
                // Store the user ID for later use.
                self.userId = uid
                
                // If the scene is already set up, load the items.
                if self.hasSceneBeenSetUp {
                    Task {
                        await self.loadStickersFromFirestore()
                    }
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
        
        // If we already have a user ID, load the data now.
        if userId != nil {
            Task {
                await self.loadStickersFromFirestore()
            }
        }
    }
    
    /// Creates a temporary `FoodItem` and sets it on the `newSticker` property
    /// so the animation view has the data it needs to start immediately.
    /// - Parameter isSpecial: Whether the new sticker is special.
    /// - Returns: The `UUID` of the newly created item, to be passed to the background saving task.
    func prepareForAnimation(isSpecial: Bool) -> UUID {
        let stickerID = UUID()
        let tempItem = FoodItem(
            id: stickerID,
            creationDate: Date(),
            imageURLString: "", // Will be populated by the background task
            thumbnailURLString: "", // Will be populated by the background task
            originalImageURLString: nil,
            isFood: nil,
            name: "Thinking...", // Placeholder name
            description: nil,
            isSpecial: isSpecial // Set immediately for the UI
        )
        
        print("[HomeViewModel] Preparing for animation. New sticker ID: \(stickerID). Is Special: \(isSpecial)")
        self.newSticker = tempItem
        self.stickerToCommit = tempItem
        
        return stickerID
    }
    
    /// This function orchestrates the sticker creation process by running the
    /// image saving and analysis tasks in the background.
    /// - Parameters:
    ///   - id: The `UUID` of the sticker, generated by `prepareForAnimation`.
    ///   - originalImage: The original image taken by the camera.
    ///   - stickerImage: The final `UIImage` of the sticker.
    func processNewSticker(id: UUID, originalImage: UIImage, stickerImage: UIImage) async {
        // 1. Set state to show a loading UI.
        print("[HomeViewModel] Starting processNewSticker in the background.")
        
        guard let userId = self.userId else {
            // Since this runs in the background, we can't show a normal error.
            // In a real app, you might log this to a service like Crashlytics.
            print("User not authenticated. Cannot save sticker.")
            return
        }
        
        // 2. Launch saving and analysis tasks in parallel.
        // We use the 'isSpecial' flag from the temporary item created for the UI.
        let isSpecial = newSticker?.isSpecial ?? false
        async let savingTask: FoodItem = firestoreService.createSticker(id: id, originalImage: originalImage, stickerImage: stickerImage, for: userId, isSpecial: isSpecial)
        async let analysisTask = analysisService.analyzeFoodImage(stickerImage, isSpecial: isSpecial)

        do {
            // 3. Await the SAVING task first. This now happens in the background.
            let savedItemWithURLs = try await savingTask

            // 4. Update the UI on the main thread with the new URLs.
            await MainActor.run {
                if self.newSticker?.id == id {
                    self.newSticker?.imageURLString = savedItemWithURLs.imageURLString
                    self.newSticker?.thumbnailURLString = savedItemWithURLs.thumbnailURLString
                    self.newSticker?.originalImageURLString = savedItemWithURLs.originalImageURLString
                    self.stickerToCommit = self.newSticker
                }
            }

            // 5. Now, await the ANALYSIS task.
            let analysisResult = await analysisTask
            
            // Create a single, final version of the item with all data.
            var finalItem = savedItemWithURLs
            
            switch analysisResult {
            case .success(let foodInfo):
                finalItem.isFood = foodInfo.isFood
                finalItem.name = foodInfo.name
                finalItem.description = foodInfo.description
            case .failure(let error):
                finalItem.isFood = false // If analysis fails, assume it's not food.
                finalItem.name = "Analysis Failed"
                finalItem.description = "Could not analyze this item. Please try again."
                print("[HomeViewModel] Food analysis failed: \(error)")
            }

            // 6. Save the analysis data to Firestore.
            print("[HomeViewModel] Saving analysis data to Firestore...")
            try await firestoreService.updateSticker(finalItem, for: userId)
            
            // 7. Update the local view model consistently.
            await MainActor.run {
                // If the detail view is still showing this sticker, update it.
                if self.newSticker?.id == finalItem.id {
                    self.newSticker = finalItem
                }
                
                // If this sticker is the one pending commit, update the reference
                // so the fully-analyzed version is what gets dropped in the jar.
                if self.stickerToCommit?.id == finalItem.id {
                    self.stickerToCommit = finalItem
                }
                
                // --- FIX: Update the item in the main array as well ---
                // This handles the case where the user dismissed the sheet before
                // analysis completed. The item is already in the jar, but its
                // local data is stale. This ensures it gets updated.
                if let index = self.foodItems.firstIndex(where: { $0.id == finalItem.id }) {
                    print("[HomeViewModel] Analysis for committed sticker \(finalItem.id) complete. Updating master list.")
                    self.foodItems[index] = finalItem
                }
            }

        } catch {
            // This 'catch' block will catch errors from the `savingTask`
            // self.isSavingSticker = false
        }
    }
    
    /// Checks if there's a pending new sticker and commits it to the main
    /// collection and the physics scene. This is called after the detail
    /// view for a new sticker is dismissed.
    func commitNewStickerIfNecessary() {
        // Use the private, safe-guarded copy of the sticker.
        // If this is nil, it means we weren't in a new-sticker flow, so we do nothing.
        guard let itemToAdd = stickerToCommit else {
            print("[HomeViewModel] commitNewStickerIfNecessary called, but no sticker to commit.")
            return
        }
        
        print("[HomeViewModel] Committing sticker ID \(itemToAdd.id) to the jar.")
        // 1. Add the sticker to the main data array.
        foodItems.append(itemToAdd)
        
        // 2. Add the sticker to the physics scene, triggering the animation.
        jarScene.addSticker(item: itemToAdd)
        
        // 3. Clear all temporary state to signify the commit is complete.
        print("[HomeViewModel] Sticker committed. Clearing all temporary state.")
        stickerToCommit = nil
        newSticker = nil
    }
    
    // MARK: - Private Methods
    
    /// Loads the user's stickers from Firestore and populates the physics scene.
    private func loadStickersFromFirestore() async {
        guard let userId = userId else {
            print("HomeViewModel: Cannot load stickers, user ID is missing.")
            return
        }
        
        print("HomeViewModel: Starting to load stickers from Firestore for user \(userId)...")
        do {
            let loadedItems = try await firestoreService.loadStickers(for: userId)
            self.foodItems = loadedItems
            print("HomeViewModel: Successfully loaded \(loadedItems.count) stickers. Populating scene.")
            jarScene.populateJar(with: self.foodItems)
        } catch {
            print("HomeViewModel: An error occurred while loading stickers from Firestore: \(error.localizedDescription)")
            // Optionally, handle the error further (e.g., show an alert to the user).
        }
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