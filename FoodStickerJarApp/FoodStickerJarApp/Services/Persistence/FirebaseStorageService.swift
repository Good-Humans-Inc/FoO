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
    
    /// Uploads an image to a specified path in Firebase Storage and returns its download URL.
    /// - Parameters:
    ///   - data: The `Data` representation of the image.
    ///   - path: The full path (including filename) where the image should be stored.
    /// - Returns: The `URL` where the uploaded image can be downloaded from.
    func uploadImage(data: Data, at path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        print("FirebaseStorageService: Starting upload to path: \(path)")
        
        // Use modern async/await syntax for the upload.
        let _ = try await storageRef.putDataAsync(data, metadata: nil)
        
        // After upload, get the download URL.
        let downloadURL = try await storageRef.downloadURL()
        
        print("✅ FirebaseStorageService: Successfully uploaded image.")
        print("✅ FirebaseStorageService: Successfully retrieved download URL: \(downloadURL.absoluteString)")
        
        return downloadURL
    }
    
    /// A specific function to handle uploading jar thumbnail images.
    /// It constructs the correct path and calls the generic uploadImage function.
    /// - Parameters:
    ///   - image: The `UIImage` of the jar thumbnail.
    ///   - userID: The ID of the user who owns the jar.
    /// - Returns: The public `URL` of the uploaded thumbnail.
    func uploadJarThumbnail(_ image: UIImage, for userID: String) async throws -> URL {
        guard let imageData = image.pngData() else {
            throw NSError(domain: "ImageError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create PNG data from thumbnail."])
        }
        
        let path = "jar_thumbnails/\(userID)/\(UUID().uuidString).png"
        
        return try await uploadImage(data: imageData, at: path)
    }
} 
