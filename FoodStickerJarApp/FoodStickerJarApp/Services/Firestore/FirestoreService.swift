import Foundation
import FirebaseFirestore

/// A service to manage all Firestore database operations for food stickers.
class FirestoreService {
    
    // A reference to the root "users" collection in Firestore.
    private let usersCollection = Firestore.firestore().collection("users")
    
    /// A reference to the "stickers" sub-collection for a specific user.
    /// This is where all of a single user's `FoodItem` documents will be stored.
    private func stickersCollection(for uid: String) -> CollectionReference {
        return usersCollection.document(uid).collection("stickers")
    }
    
    /// Saves a new food sticker to the currently authenticated user's collection in Firestore.
    /// - Parameters:
    ///   - item: The `FoodItem` to save.
    ///   - uid: The UID of the authenticated user.
    ///   - completion: A closure that returns the saved item with its new ID, or an error.
    func saveSticker(_ item: FoodItem, for uid: String, completion: @escaping (Result<FoodItem, Error>) -> Void) {
        do {
            // Use `addDocument(from:)` to let Firestore auto-generate an ID.
            // This returns a DocumentReference.
            let ref = try stickersCollection(for: uid).addDocument(from: item)
            
            // We need to get the newly created document to return the item with its ID.
            ref.getDocument { (document, error) in
                if let document = document, document.exists {
                    do {
                        // Decode the document back into a FoodItem.
                        // This will now have the `id` property populated.
                        let savedItem = try document.data(as: FoodItem.self)
                        completion(.success(savedItem))
                    } catch {
                        completion(.failure(error))
                    }
                } else if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.failure(NSError(domain: "FirestoreService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Document does not exist."])))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    /// Fetches all food stickers for a given user from Firestore.
    /// - Parameters:
    ///   - uid: The UID of the user whose stickers to fetch.
    ///   - completion: A closure that returns an array of `FoodItem` or an error.
    func fetchStickers(for uid: String, completion: @escaping (Result<[FoodItem], Error>) -> Void) {
        stickersCollection(for: uid).getDocuments { (querySnapshot, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = querySnapshot?.documents else {
                completion(.success([]))
                return
            }
            
            // Use `compactMap` to attempt to decode each document into a `FoodItem`.
            // This will safely ignore any documents that fail to decode.
            let items = documents.compactMap { document in
                try? document.data(as: FoodItem.self)
            }
            
            completion(.success(items))
        }
    }
} 
