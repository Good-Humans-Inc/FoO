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
    ///   - image: The sticker `UIImage` to be processed and saved.
    ///   - userID: The ID of the currently authenticated user.
    /// - Returns: The fully constructed `FoodItem` with URLs pointing to the stored images.
    func createSticker(from image: UIImage, for userID: String) async throws -> FoodItem {
        let stickerID = UUID()
        let creationDate = Date()
        
        // Prepare image data.
        guard let imageData = image.pngData() else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get PNG data from image."])
        }
        
        let thumbnail = image.resized(toMaxSize: 150)
        guard let thumbnailData = thumbnail.pngData() else {
            throw NSError(domain: "ImageError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get PNG data from thumbnail."])
        }
        
        // Define paths for Firebase Storage.
        let imagePath = "stickers/\(userID)/\(stickerID.uuidString).png"
        let thumbnailPath = "stickers/\(userID)/\(stickerID.uuidString)_thumb.png"
        
        // Upload both images concurrently.
        async let imageURL = storageService.uploadImage(data: imageData, at: imagePath)
        async let thumbnailURL = storageService.uploadImage(data: thumbnailData, at: thumbnailPath)
        
        // Await the results.
        let (finalImageURL, finalThumbnailURL) = try await (imageURL, thumbnailURL)
        
        // Create the Firestore data object.
        let foodItem = FoodItem(
            id: stickerID,
            creationDate: creationDate,
            imageURLString: finalImageURL.absoluteString,
            thumbnailURLString: finalThumbnailURL.absoluteString,
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
} 
