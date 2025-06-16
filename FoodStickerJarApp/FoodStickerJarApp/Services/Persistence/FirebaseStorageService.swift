import Foundation
import FirebaseCore
import FirebaseStorage
import UIKit

/// A service dedicated to handling all Firebase Storage operations.
class FirebaseStorageService {
    
    // Get a reference to the Firebase Storage service.
    private let storage = Storage.storage()
    
    enum StorageError: Error {
        case failedToUploadImage(description: String)
        case failedToGetDownloadURL
    }
    
    /// Uploads image data to a specific path in Firebase Storage and returns the download URL.
    /// - Parameters:
    ///   - data: The image data to upload.
    ///   - path: The path where the image will be stored (e.g., "stickers/{userID}/{stickerID}.png").
    /// - Returns: The public URL of the uploaded image.
    func uploadImage(data: Data, at path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        
        print("FirebaseStorageService: Starting upload to path: \(path)")
        
        do {
            // Use modern async/await for the upload.
            _ = try await storageRef.putDataAsync(data, metadata: nil)
            print("✅ FirebaseStorageService: Successfully uploaded image.")
            
            // After uploading, fetch the download URL.
            let downloadURL = try await storageRef.downloadURL()
            print("✅ FirebaseStorageService: Successfully retrieved download URL: \(downloadURL.absoluteString)")
            return downloadURL
            
        } catch {
            print("❌ FirebaseStorageService: Error during image upload or URL retrieval.")
            print("   - Path: \(path)")
            print("   - Error Details: \(error.localizedDescription)")
            throw StorageError.failedToUploadImage(description: error.localizedDescription)
        }
    }
} 
