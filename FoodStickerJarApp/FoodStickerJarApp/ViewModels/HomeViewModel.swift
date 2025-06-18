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
    @Published var showArchiveInProgress = false
    @Published var triggerSnapshot = false
    
    // MARK: - Services and Engine
    
    // A single, persistent instance of the physics scene. This is crucial
    // to ensure the physics simulation doesn't reset every time the view updates.
    let jarScene = JarScene(size: .zero)
    
    // The service responsible for saving and loading data from Firestore.
    private let firestoreService = FirestoreService()
    // The service for analyzing food images.
    private let analysisService = FoodAnalysisService()
    // The service for handling user feedback.
    private let feedbackService = FeedbackService()
    // The service for uploading files.
    private let storageService = FirebaseStorageService()
    
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
    
    /// This function orchestrates the sticker creation process by running the
    /// image saving and analysis tasks in parallel for a faster user experience.
    /// - Parameter originalImage: The original image taken by the camera.
    /// - Parameter stickerImage: The final `UIImage` of the sticker.
    func processNewSticker(originalImage: UIImage, stickerImage: UIImage) async {
        // 1. Set state to show a loading UI.
        await MainActor.run {
            self.stickerCreationError = nil
            self.isSavingSticker = true
        }

        guard let userId = self.userId else {
            await MainActor.run {
                self.stickerCreationError = "User not authenticated. Cannot save sticker."
                self.isSavingSticker = false
            }
            return
        }
        
        // 2. Launch saving and analysis tasks in parallel.
        async let savingTask: FoodItem = firestoreService.createSticker(originalImage: originalImage, stickerImage: stickerImage, for: userId)
        async let analysisTask = analysisService.analyzeFoodImage(stickerImage)

        do {
            // 3. Await the SAVING task first. This is the critical path to showing the UI.
            let newItem = try await savingTask

            // 4. As soon as we have the new item, show the UI. The loading indicator will hide.
            await MainActor.run {
                self.newSticker = newItem
                self.stickerToCommit = newItem // Prepare for commit
                self.isSavingSticker = false // Hide loading overlay
            }

            // 5. Now, await the ANALYSIS task.
            let analysisResult = await analysisTask
            
            var updatedItem = newItem
            
            switch analysisResult {
            case .success(let foodInfo):
                updatedItem.name = foodInfo.name
                updatedItem.funFact = foodInfo.funFact
                updatedItem.nutrition = foodInfo.nutrition
            case .failure(let error):
                updatedItem.name = "Analysis Failed"
                print("Food analysis failed: \(error)")
            }

            // 6. Save the analysis data to Firestore.
            try await firestoreService.updateSticker(updatedItem, for: userId)
            
            // 7. Update the local view model consistently.
            await MainActor.run {
                // If the detail view is still showing this sticker, update it.
                if self.newSticker?.id == updatedItem.id {
                    self.newSticker = updatedItem
                }
                
                // If this sticker is the one pending commit, update the reference
                // so the fully-analyzed version is what gets dropped in the jar.
                if self.stickerToCommit?.id == updatedItem.id {
                    self.stickerToCommit = updatedItem
                }
            }

        } catch {
            // This 'catch' block will catch errors from the `savingTask` (the critical path).
            await MainActor.run {
                print("❌ HomeViewModel: Failed to create and save sticker.")
                print("   - Error: \(error.localizedDescription)")
                self.stickerCreationError = error.localizedDescription
                self.isSavingSticker = false
            }
        }
    }
    
    /// Checks if there's a pending new sticker and commits it to the main
    /// collection and the physics scene. This is called after the detail
    /// view for a new sticker is dismissed.
    func commitNewStickerIfNecessary() {
        // Use the private, safe-guarded copy of the sticker.
        // If this is nil, it means we weren't in a new-sticker flow, so we do nothing.
        guard let itemToAdd = stickerToCommit else {
            return
        }
        
        // 1. Add the sticker to the main data array.
        foodItems.append(itemToAdd)
        
        // 2. Add the sticker to the physics scene, triggering the animation.
        jarScene.addSticker(item: itemToAdd)
        
        // 3. Clear the temporary item to signify the commit is complete.
        stickerToCommit = nil
    }
    
    /// Submits user-provided feedback via the FeedbackService.
    /// - Parameter message: The string content of the feedback.
    func submitFeedback(_ message: String) {
        // Basic validation: ensure the feedback isn't empty.
        guard !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("HomeViewModel: Feedback message is empty, not submitting.")
            return
        }
        
        feedbackService.submitFeedback(message: message)
    }
    
    // MARK: - Archiving
    
    func archiveJar(with image: UIImage) async {
        showArchiveInProgress = true
        
        guard let userId = self.userId else {
            print("Error: User not authenticated.")
            showArchiveInProgress = false
            return
        }
        
        guard !foodItems.isEmpty else {
            print("Jar is empty, nothing to archive.")
            showArchiveInProgress = false
            return
        }
        
        guard let imageData = image.pngData() else {
            print("Error: Could not convert image to PNG data.")
            showArchiveInProgress = false
            return
        }
        
        do {
            let imagePath = "jar_thumbnails/\(userId)/\(UUID().uuidString).png"
            let imageURL = try await storageService.uploadImage(data: imageData, at: imagePath)
            
            let stickerIDs = foodItems.map { $0.id.uuidString }
            
            _ = try await firestoreService.archiveJar(stickerIDs: stickerIDs, screenshotURL: imageURL.absoluteString, for: userId)
            
            // Clear the jar
            foodItems.removeAll()
            jarScene.clear()
            
            print("Successfully archived jar.")
            
        } catch {
            print("Error archiving jar: \(error.localizedDescription)")
            // Optionally, show an error to the user
        }
        
        showArchiveInProgress = false
    }
    
    func initiateArchiving() {
        triggerSnapshot = true
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
