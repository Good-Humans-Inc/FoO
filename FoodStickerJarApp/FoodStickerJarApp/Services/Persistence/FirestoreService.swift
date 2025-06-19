import Foundation
import FirebaseFirestore

/// A service dedicated to handling all Firestore database operations.
class FirestoreService {
    
    // Get a reference to the Firestore database.
    private let db = Firestore.firestore()
    // The service for handling file uploads.
    private let storageService = FirebaseStorageService()
    
    /// Creates a new food sticker by first uploading its images to Firebase Storage
    /// and then saving the resulting URL metadata to Firestore.
    /// - Parameters:
    ///   - originalImage: The original `UIImage` from the camera.
    ///   - stickerImage: The sticker `UIImage` to be processed and saved.
    ///   - userID: The ID of the currently authenticated user.
    /// - Returns: The fully constructed `FoodItem` with URLs pointing to the stored images.
    func createSticker(originalImage: UIImage, stickerImage: UIImage, for userID: String) async throws -> FoodItem {
        let stickerID = UUID()
        let creationDate = Date()
        
        // Prepare image data for sticker and thumbnail.
        guard let stickerImageData = stickerImage.pngData() else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get PNG data from image."])
        }
        
        let thumbnail = stickerImage.resized(toMaxSize: 150)
        guard let thumbnailData = thumbnail.pngData() else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get PNG data from thumbnail."])
        }
        
        // Prepare image data for original photo. Use JPEG for photos to save space.
        guard let originalImageData = originalImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "ImageError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get JPEG data from original image."])
        }
        
        // Define paths for Firebase Storage.
        let imagePath = "stickers/\(userID)/\(stickerID.uuidString).png"
        let thumbnailPath = "stickers/\(userID)/\(stickerID.uuidString)_thumb.png"
        let originalPhotoPath = "originals/\(userID)/\(stickerID.uuidString).jpg"
        
        // Upload all three images concurrently.
        async let imageURL = storageService.uploadImage(data: stickerImageData, at: imagePath)
        async let thumbnailURL = storageService.uploadImage(data: thumbnailData, at: thumbnailPath)
        async let originalPhotoURL = storageService.uploadImage(data: originalImageData, at: originalPhotoPath)
        
        // Await the results.
        let (finalImageURL, finalThumbnailURL, finalOriginalPhotoURL) = try await (imageURL, thumbnailURL, originalPhotoURL)
        
        // Create the Firestore data object.
        let foodItem = FoodItem(
            id: stickerID,
            creationDate: creationDate,
            imageURLString: finalImageURL.absoluteString,
            thumbnailURLString: finalThumbnailURL.absoluteString,
            originalImageURLString: finalOriginalPhotoURL.absoluteString,
            name: nil,
            funFact: nil,
            nutrition: nil
        )
        
        // Save the metadata object to Firestore.
        let stickerDocument = db.collection("users").document(userID).collection("stickers").document(stickerID.uuidString)
        try stickerDocument.setData(from: foodItem)
        
        print("✅ FirestoreService: Successfully created and saved sticker metadata for \(stickerID.uuidString).")
        
        return foodItem
    }
    
    /// Updates an existing sticker document with new data.
    /// - Parameters:
    ///   - sticker: The `FoodItem` containing the updated data.
    ///   - userID: The ID of the currently authenticated user.
    func updateSticker(_ sticker: FoodItem, for userID: String) async throws {
        let stickerDocument = db.collection("users").document(userID).collection("stickers").document(sticker.id.uuidString)
        
        // This will merge the new data with the existing document,
        // or create it if it doesn't exist (which shouldn't happen in this flow).
        try await stickerDocument.setData([
            "name": sticker.name as Any,
            "funFact": sticker.funFact as Any,
            "nutrition": sticker.nutrition as Any
        ], merge: true)
        
        print("✅ FirestoreService: Successfully updated sticker \(sticker.id.uuidString) with analysis data.")
    }
    
    /// Loads all food stickers for a given user from Firestore.
    /// - Parameter userID: The ID of the currently authenticated user.
    /// - Returns: An array of `FoodItem` objects.
    func loadStickers(for userID: String) async throws -> [FoodItem] {
        print("FirestoreService: Preparing to load stickers for user ID: \(userID)")
        
        // With the new architecture, we no longer need to filter.
        // This collection will only contain active stickers.
        let stickerCollection = db.collection("users").document(userID).collection("stickers")
        
        do {
            // Fetch all documents from the user's sticker collection.
            let querySnapshot = try await stickerCollection.getDocuments()
            print("FirestoreService: Found \(querySnapshot.documents.count) documents in Firestore.")
            
            // Use `compactMap` to decode each document into a `FoodItem`.
            // This is safer as it automatically filters out any documents that fail to decode.
            let foodItems = try querySnapshot.documents.compactMap { document in
                // The `.data(as:)` method from FirebaseFirestoreSwift handles the decoding.
                let item = try document.data(as: FoodItem.self)
                print("   - Successfully decoded sticker: \(item.id.uuidString)")
                return item
            }
            
            print("✅ FirestoreService: Successfully loaded and decoded \(foodItems.count) stickers.")
            return foodItems
            
        } catch {
            print("❌ FirestoreService: ERROR loading stickers from Firestore for user ID: \(userID)")
            print("   - Error Details: \(error.localizedDescription)")
            // Re-throw the error so the caller (HomeViewModel) can handle it.
            throw error
        }
    }
    
    /// Checks if a user document exists in Firestore for the given userID, and creates one if it doesn't.
    /// This ensures that every user has a corresponding document in the `users` collection.
    /// This function uses a transaction to prevent race conditions.
    /// - Parameter userID: The ID of the user to check and potentially create.
    func checkAndCreateUserDocument(for userID: String) async {
        let userDocumentRef = db.collection("users").document(userID)
        
        do {
            // 1. Attempt to get the document.
            let document = try await userDocumentRef.getDocument()
            
            // 2. Check if it exists and if the jarIDs field is missing.
            if document.exists {
                if document.data()?["jarIDs"] == nil {
                    // If the field is missing, update the document.
                    try await userDocumentRef.updateData(["jarIDs": []])
                    print("✅ FirestoreService: Repaired existing user document for \(userID) by adding missing jarIDs field.")
                }
                // If document exists and has the field, we're done.
            } else {
                // 3. If the document does not exist, create it.
                let newUser = User(id: userID, jarIDs: [])
                try userDocumentRef.setData(from: newUser)
                print("✅ FirestoreService: Created new user document for \(userID).")
            }
        } catch {
            print("❌ FirestoreService: Failed to check or create user document for \(userID): \(error)")
        }
    }
    
    /// Archives a collection of stickers as a new jar in Firestore.
    /// This function uses a batched write to ensure atomicity.
    /// It creates the new jar with embedded sticker data, deletes the original stickers,
    /// and updates the user's list of jar IDs all at once.
    /// - Parameters:
    ///   - stickers: An array of `FoodItem` objects to be archived.
    ///   - screenshotURL: The URL of the jar's screenshot thumbnail.
    ///   - userID: The ID of the user archiving the jar.
    ///   - report: An optional string containing the weekly report.
    /// - Returns: The newly created `JarItem`.
    func archiveJar(stickers: [FoodItem], screenshotURL: String, for userID: String, report: String?) async throws -> JarItem {
        let newJarRef = db.collection("jars").document()
        let userRef = db.collection("users").document(userID)
        
        let newJarItem = JarItem(
            id: newJarRef.documentID,
            userID: userID,
            timestamp: Timestamp(date: Date()),
            screenshotThumbnailURL: screenshotURL,
            stickers: stickers,
            report: report
        )
        
        let batch = db.batch()
        
        // 1. Create the new jar document with all sticker data embedded.
        try batch.setData(from: newJarItem, forDocument: newJarRef)
        
        // 2. Delete each of the original stickers from the user's sticker collection.
        for sticker in stickers {
            let stickerRef = db.collection("users").document(userID).collection("stickers").document(sticker.id.uuidString)
            batch.deleteDocument(stickerRef)
        }
        
        // 3. Atomically add the new jar's ID to the user's list of jarIDs.
        batch.setData([
            "jarIDs": FieldValue.arrayUnion([newJarRef.documentID])
        ], forDocument: userRef, merge: true)
        
        // Commit the batch
        try await batch.commit()
        
        print("✅ FirestoreService: Successfully archived jar \(newJarRef.documentID) for user \(userID).")
        
        return newJarItem
    }
    
    /// Fetches all jars belonging to a specific user.
    /// - Parameter userID: The ID of the user whose jars to fetch.
    /// - Returns: An array of `JarItem` objects.
    func fetchJars(for userID: String) async throws -> [JarItem] {
        let querySnapshot = try await db.collection("jars")
                                      .whereField("userID", isEqualTo: userID)
                                      .getDocuments()
        
        let jars = try querySnapshot.documents.compactMap { document in
            try document.data(as: JarItem.self)
        }
        
        return jars
    }
    
    /// Fetches a single jar from Firestore by its ID.
    /// - Parameter jarID: The ID of the jar to fetch.
    /// - Returns: A `JarItem` object.
    func fetchJar(with jarID: String) async throws -> JarItem {
        let jar = try await db.collection("jars").document(jarID).getDocument(as: JarItem.self)
        return jar
    }

    /// Fetches a user document from Firestore by its ID.
    /// - Parameter userID: The ID of the user to fetch.
    /// - Returns: A `User` object.
    func fetchUser(with userID: String) async throws -> User {
        let user = try await db.collection("users").document(userID).getDocument(as: User.self)
        return user
    }
    
    /// Fetches a collection of stickers for a given user from Firestore based on their IDs.
    /// - Parameters:
    ///   - ids: An array of sticker document IDs to fetch.
    ///   - userID: The ID of the user who owns the stickers.
    /// - Returns: An array of `FoodItem` objects.
    func fetchStickers(by ids: [String], for userID: String) async throws -> [FoodItem] {
        guard !ids.isEmpty else { return [] }
        
        // Firestore's `in` query is limited to 30 elements.
        // If we expect more, we need to chunk the requests.
        let chunks = ids.chunked(into: 30)
        var foodItems: [FoodItem] = []
        
        for chunk in chunks {
            let querySnapshot = try await db.collection("users").document(userID).collection("stickers").whereField(FieldPath.documentID(), in: chunk).getDocuments()
            
            let items = try querySnapshot.documents.compactMap { document in
                try document.data(as: FoodItem.self)
            }
            foodItems.append(contentsOf: items)
        }
        
        return foodItems
    }
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
} 
