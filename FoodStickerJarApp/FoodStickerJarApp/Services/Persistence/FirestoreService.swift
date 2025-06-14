import Foundation
import FirebaseFirestore

/// A service dedicated to handling all Firestore database operations.
class FirestoreService {
    
    // Get a reference to the Firestore database.
    private let db = Firestore.firestore()
    
    /// Saves a new food sticker to the user's collection in Firestore.
    /// - Parameters:
    ///   - foodItem: The `FoodItem` object containing all sticker data.
    ///   - userID: The ID of the currently authenticated user.
    func saveSticker(_ foodItem: FoodItem, for userID: String) {
        print("FirestoreService: Preparing to save sticker for user ID: \(userID)")
        print("FirestoreService: Sticker ID: \(foodItem.id.uuidString)")
        
        // Define the path to the user's specific "stickers" collection.
        let stickerCollection = db.collection("users").document(userID).collection("stickers")
        
        // Use the FoodItem's unique ID as the document ID in Firestore.
        let stickerDocument = stickerCollection.document(foodItem.id.uuidString)
        
        // Attempt to encode the FoodItem and save it.
        do {
            print("FirestoreService: Encoding FoodItem to be saved...")
            // The `setData(from:)` method automatically converts the Codable `foodItem`
            // into a format Firestore can understand.
            try stickerDocument.setData(from: foodItem)
            print("✅ FirestoreService: Successfully saved sticker \(foodItem.id.uuidString) to Firestore.")
        } catch {
            // If the save operation fails, log the specific error.
            print("❌ FirestoreService: ERROR saving sticker to Firestore.")
            print("   - User ID: \(userID)")
            print("   - Sticker ID: \(foodItem.id.uuidString)")
            print("   - Error Details: \(error.localizedDescription)")
        }
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
