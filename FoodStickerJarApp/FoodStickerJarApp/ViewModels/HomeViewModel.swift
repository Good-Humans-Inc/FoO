import SwiftUI
import Combine
import UserNotifications

struct ErrorAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}

struct ReportWrapper: Identifiable {
    let id = UUID()
    let report: String
}

// This class manages the state and logic for the HomeView.
// @MainActor ensures that any changes to its @Published properties
// happen on the main thread, which is required for UI updates.
@MainActor
class HomeViewModel: ObservableObject {

    // MARK: - Published Properties
    // These properties will trigger UI updates whenever they change.
    
    // The master list of all food items.
    @Published var foodItems: [FoodItem] = []
    
    // The user's profile data.
    @Published var userProfile: User?
    
    // The detail view is now managed by the router.
    // We hold a reference to it to communicate selections.
    private let navigationRouter: NavigationRouter
    
    // Holds the newly created sticker to be shown in the detail sheet
    // before it's added to the main jar.
    @Published var newSticker: FoodItem?
    
    // A private copy to hold the fully-analyzed sticker, avoiding a race condition
    // when the view is dismissed.
    private var stickerToCommit: FoodItem?
    
    // Holds the generated UIImage of the new sticker, so it can be passed
    // directly to the JarScene without waiting for the URL to be available.
    private var stickerImageToCommit: UIImage?
    
    // State properties for managing the sticker creation UI flow.
    @Published var isSavingSticker = false
    @Published var showArchiveInProgress = false
    
    // State properties for presenting alerts and sheets.
    // Using Identifiable wrappers is the modern, reliable way to trigger views.
    @Published var errorAlert: ErrorAlert?
    @Published var newlyGeneratedReportWrapper: ReportWrapper?
    
    // A reference to the view that can be snapshotted.
    // This is a workaround to avoid SwiftUI's view-based snapshotting limitations
    // when the trigger comes from a non-view event (like a long press in SpriteKit).
    var jarViewForSnapshotting: JarContainerView?
    
    // A flag to ensure the commit logic only runs for newly created stickers,
    // not when viewing an old sticker's detail card.
    private var isCommittingNewSticker = false
    
    private let instanceID = UUID()
    
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
    // The service for generating weekly reports.
    private let reportGenerationService = ReportGenerationService()
    
    // Used to receive notifications from the JarScene when a sticker is tapped.
    private var cancellables = Set<AnyCancellable>()

    // The authenticated user's ID, captured on login.
    private var userId: String?
    
    // A flag to ensure the scene is set up only once.
    private var hasSceneBeenSetUp = false

    // MARK: - Initializer
    
    init(authService: AuthenticationService, navigationRouter: NavigationRouter) {
        self.navigationRouter = navigationRouter
        
        print("✅ [HomeViewModel] INIT instance \(instanceID)")
        
        // Scene communication needs to be set up immediately.
        // The scene itself will be populated once its size is known from the view.
        setupJarSceneCommunication()
        setupAutoArchiveListeners()
        
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
                
                Task {
                    await self.loadUserProfile()
                }
            }
            .store(in: &cancellables)
    }
    
    deinit {
        print("❌ [HomeViewModel] DEINIT instance \(instanceID)")
    }
    
    // MARK: - Public Methods
    
    /// Sets up listeners for auto-archiving events.
    private func setupAutoArchiveListeners() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }

    @objc private func appDidBecomeActive() {
        print("[HomeViewModel] App became active. Checking for weekly archive.")
        Task {
            await checkForAutoArchive(from: "weeklyCheck")
        }
    }
    
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
            name: "Casting spell...", // Placeholder name
            funFact: nil,
            isSpecial: isSpecial // Set immediately for the UI
        )
        
        print("[HomeViewModel] Preparing for animation. New sticker ID: \(stickerID). Is Special: \(isSpecial)")
        self.newSticker = tempItem
        self.stickerToCommit = tempItem
        
        // This indicates that a new sticker is in the process of being created.
        self.isCommittingNewSticker = true
        
        return stickerID
    }
    
    /// This function orchestrates the sticker creation process by running the
    /// image saving and analysis tasks in the background.
    /// - Parameters:
    ///   - id: The `UUID` of the sticker, generated by `prepareForAnimation`.
    ///   - originalImage: The original image taken by the camera.
    ///   - stickerImage: The final `UIImage` of the sticker.
    func processStickerInCloud(id: UUID, originalImage: UIImage, stickerImage: UIImage) async {
        // 1. Set state to show a loading UI.
        print("[HomeViewModel] Starting to process sticker in the cloud in the background.")
        
        // --- FIX: Store the local UIImage for the commit ---
        self.stickerImageToCommit = stickerImage
        
        // Determine if the sticker is special to play the correct sound.
        let isSpecial = newSticker?.isSpecial ?? false
        if isSpecial {
            SoundManager.shared.playSound(named: "specialGen")
        } else {
            SoundManager.shared.playSound(named: "normyGen")
        }
        
        guard let userId = self.userId else {
            // Since this runs in the background, we can't show a normal error.
            // In a real app, you might log this to a service like Crashlytics.
            print("User not authenticated. Cannot save sticker.")
            return
        }
        
        // 2. Launch saving and analysis tasks in parallel.
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
                finalItem.funFact = foodInfo.funFact
            case .failure(let error):
                finalItem.isFood = false // If analysis fails, assume it's not food.
                finalItem.name = "Analysis Failed"
                print("❌ [HomeViewModel] Food analysis failed. Error: \(error.localizedDescription)")
                // Log the detailed error for debugging
                switch error {
                case .decodingError(let decodingError):
                    print("❌ [HomeViewModel] Decoding Error Details: \(decodingError)")
                default:
                    break // Other errors are already descriptive enough
                }
            }

            // 6. Save the analysis data (and any special content) to Firestore.
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
                
                // After successfully creating a sticker, reload the user profile
                // to get the updated sticker count.
                Task {
                    await self.loadUserProfile()
                }
                
                // --- FIX: Update the item in the main array as well ---
                // This handles the case where the user dismissed the sheet before
                // analysis completed. The item is already in the jar, but its
                // local data is stale. This ensures it gets updated.
                if let index = self.foodItems.firstIndex(where: { $0.id == finalItem.id }) {
                    print("[HomeViewModel] Analysis for committed sticker \(finalItem.id) complete. Updating master list.")
                    self.foodItems[index] = finalItem
                }
                
                // If the user is currently viewing the detail of the sticker that just
                // finished analyzing, we must also update the selectedFoodItem directly.
                // This ensures the detail view, which is bound to selectedFoodItem, refreshes immediately.
                if self.navigationRouter.selectedFoodItem?.id == finalItem.id {
                    print("[HomeViewModel] Refreshing currently visible detail view.")
                    self.navigationRouter.selectedFoodItem = finalItem
                }
            }
            print("[HomeViewModel] ✅ BACKGROUND_TASK: Cloud processing finished for sticker \(id).")

        } catch {
            await MainActor.run {
                errorAlert = ErrorAlert(title: "Sticker Creation Failed", message: "Failed to create sticker. Error: \(error.localizedDescription)")
                // Clean up the temporary state so the user isn't stuck.
                print("💥 Calling reset from BACKGROUND CATCH BLOCK")
                resetStickerCreationState()
            }
            print("[HomeViewModel] ❌ BACKGROUND_TASK: Cloud processing FAILED for sticker \(id). Error: \(error.localizedDescription)")
        }
    }
    
    /// This is the single entry point for finalizing the sticker creation process.
    /// It should be called when the creation UI is dismissed.
    /// It ensures the sticker is committed before state is cleared, preventing race conditions.
    func handleStickerCreationDismissal() {
        // Instead of checking a separate flag, we now check for the data itself.
        // This is more robust against race conditions.
        print("➡️ [HomeViewModel] handleStickerCreationDismissal called on instance \(instanceID).")
        guard let sticker = self.stickerToCommit, let image = self.stickerImageToCommit else {
            // If there's no sticker data, we are not in a commit flow. Do nothing.
            print("   - 💥 GUARD FAILED: stickerToCommit or stickerImageToCommit is nil.")
            return
        }
        
        // Pass the sticker and image data as arguments to make the commit
        // function independent of the view model's state.
        commitStickerToJar(sticker: sticker, image: image)
        
        // Now that the commit function has its own reference to the data,
        // we can safely and immediately reset the state.
        resetStickerCreationState()
    }
    
    /// Resets the temporary state associated with sticker creation. This should be
    /// called after a successful commit or an explicit cancellation.
    func resetStickerCreationState() {
        self.newSticker = nil
        self.stickerToCommit = nil
        self.stickerImageToCommit = nil
        // --- FIX: Reset the commit flag ---
        // The commit process is complete, so we reset the flag.
        self.isCommittingNewSticker = false
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
    
    /// Initiates the process of archiving the current jar.
    func initiateArchiving() {
        guard !foodItems.isEmpty else {
            print("[HomeViewModel] No items to archive.")
            return
        }
        
        guard let viewToSnapshot = jarViewForSnapshotting, let image = viewToSnapshot.snapshot()?.croppedToOpaque() else {
            errorAlert = ErrorAlert(title: "Archive Failed", message: "Could not capture a snapshot of the jar. Please try again.")
            return
        }
        
        showArchiveInProgress = true
        
        Task {
            await archiveJar(with: image)
        }
    }
    
    /// The main function for creating a new jar from the existing stickers.
    /// This is triggered by the `HomeView` after it captures a snapshot.
    /// - Parameter image: The `UIImage` snapshot of the jar view.
    func archiveJar(with image: UIImage) async {
        guard let userId = self.userId, !foodItems.isEmpty else {
            errorAlert = ErrorAlert(title: "Archive Failed", message: "Could not archive jar: user not logged in or no items in the jar.")
            showArchiveInProgress = false
            return
        }
        
        print("[HomeViewModel] Archiving jar with \(foodItems.count) stickers.")

        do {
            // 1. Generate a report for the current set of stickers.
            let report = try await reportGenerationService.generateReport(for: foodItems)
            print("[HomeViewModel] Report generated successfully.")
            
            // 2. Upload the jar's screenshot.
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get JPEG data from screenshot."])
            }
            let imagePath = "screenshots/\(userId)/\(UUID().uuidString).jpg"
            let screenshotURL = try await storageService.uploadImage(data: imageData, at: imagePath)
            print("[HomeViewModel] Screenshot uploaded to \(screenshotURL).")
            
            // 3. Create the new JarItem in Firestore and delete the old stickers.
            let archivedJar = try await firestoreService.archiveJar(
                stickers: foodItems,
                screenshotURL: screenshotURL.absoluteString,
                for: userId,
                report: report
            )
            
            print("[HomeViewModel] Jar \(archivedJar.id ?? "N/A") successfully created in Firestore.")
            
            // 4. Update UI state on the main thread.
            self.newlyGeneratedReportWrapper = ReportWrapper(report: report)
            
            // 5. Update the last archive date
            UserDefaults.standard.set(Date(), forKey: "lastArchiveDate")

        } catch {
            print("[HomeViewModel] Error archiving jar: \(error.localizedDescription)")
            errorAlert = ErrorAlert(title: "Archive Failed", message: "Failed to archive the jar. Please try again. Error: \(error.localizedDescription)")
            showArchiveInProgress = false
        }
    }
    
    /// Clears the local state after the archiving process is complete.
    func finalizeArchiving(clearLocalStickers: Bool) {
        if clearLocalStickers {
            self.foodItems.removeAll()
        }
        
        // Hide the progress indicator.
        self.showArchiveInProgress = false
        
        guard let reportImage = UIImage(named: "reportScroll") else {
            print("Could not load reportScroll image asset.")
            self.clearJarView() // Clear without animation if image is missing
            return
        }

        let reportSticker = FoodItem(
            id: UUID(),
            creationDate: Date(),
            imageURLString: "",
            thumbnailURLString: "",
            originalImageURLString: nil,
            name: "Weekly Report"
        )

        jarScene.addSticker(foodItem: reportSticker, image: reportImage)
        
        // Schedule the jar clearing animation after a delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.animateAndClearJar()
        }
    }

    private func animateAndClearJar() {
        jarScene.animateStickersVanishing {
            self.jarScene.clear()
        }
    }

    /// Clears all stickers from the jar view without animation.
    func clearJarView() {
        jarScene.clear()
    }
    
    // MARK: - Private Helper Methods
    
    private func commitStickerToJar(sticker: FoodItem, image: UIImage) {
        if !foodItems.contains(where: { $0.id == sticker.id }) {
            foodItems.append(sticker)
            jarScene.addSticker(foodItem: sticker, image: image, isNew: true)
            
            // Check for auto-archive in case this sticker filled the jar.
            Task {
                await self.checkForAutoArchive(from: "newStickerCommit")
            }
        }
        
        // DO NOT clean up state here. The calling view is responsible for this
        // to ensure the commit completes before the state is cleared.
    }
    
    private func checkForAutoArchive(from source: String) async {
        print("[HomeViewModel] Checking for auto-archive, triggered by: \(source).")
        
        let stickerCount = foodItems.count
        print("*******[HomeViewModel] Sticker count: \(stickerCount)")
        let isJarFull = stickerCount > 21
        
        // Weekly Check Logic
        let calendar = Calendar.current
        let today = Date()
        let isSunday = calendar.component(.weekday, from: today) == 1 // 1 is Sunday
        
        var shouldWeeklyArchive = false
        if isSunday {
            if let lastArchive = UserDefaults.standard.object(forKey: "lastArchiveDate") as? Date {
                // If it's Sunday, check if the last archive was before the most recent Sunday.
                if !calendar.isDate(lastArchive, inSameDayAs: today) && lastArchive < today {
                    shouldWeeklyArchive = true
                }
            } else {
                // If we've never archived, and it's Sunday, do it.
                shouldWeeklyArchive = true
            }
        }
        
        if isJarFull || shouldWeeklyArchive {
            print("[HomeViewModel] Auto-archive condition met. Jar full: \(isJarFull), Weekly archive: \(shouldWeeklyArchive).")
            initiateArchiving()
        }
    }
    
    /// Loads the user's stickers from Firestore and populates the physics scene.
    private func loadStickersFromFirestore() async {
        guard let userId = self.userId else {
            print("HomeViewModel: Cannot load stickers, user ID is nil.")
            return
        }
        
        print("HomeViewModel: Starting to load stickers from Firestore for user \(userId)...")
        do {
            let loadedItems = try await firestoreService.loadStickers(for: userId)
            self.foodItems = loadedItems
            print("HomeViewModel: Successfully loaded \(loadedItems.count) stickers. Populating scene.")
            jarScene.populateJar(with: self.foodItems)
            
            // Now that stickers are loaded, check if an archive is needed.
            // This fixes the race condition on startup where the check ran before stickers were loaded.
            await checkForAutoArchive(from: "postStickerLoad")
        } catch {
            print("HomeViewModel: An error occurred while loading stickers from Firestore: \(error.localizedDescription)")
            // Optionally, handle the error further (e.g., show an alert to the user).
        }
    }
    
    /// Listens for tap events broadcasted from the JarScene.
    private func setupJarSceneCommunication() {
        jarScene.onStickerTapped
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tappedItemID in
                guard let self = self else { return }
                if let tappedItem = self.foodItems.first(where: { $0.id == tappedItemID }) {
                    // Tell the router to present the detail view.
                    self.navigationRouter.selectedFoodItem = tappedItem
                }
            }
            .store(in: &cancellables)
            
        jarScene.onStickerLongPressed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                print("[HomeViewModel] Long press detected, initiating manual archive.")
                self?.initiateArchiving()
            }
            .store(in: &cancellables)
    }
    
    /// Loads the current user's profile from Firestore.
    func loadUserProfile() async {
        guard let userId = self.userId else {
            print("HomeViewModel: Cannot load user profile, user ID is nil.")
            return
        }
        
        do {
            let user = try await firestoreService.fetchUser(for: userId)
            await MainActor.run {
                self.userProfile = user
                print("✅ HomeViewModel: Successfully loaded user profile. Sticker count: \(user.stickerCount ?? 0)")
            }
        } catch {
            print("❌ HomeViewModel: Failed to load user profile: \(error.localizedDescription)")
        }
    }
}
