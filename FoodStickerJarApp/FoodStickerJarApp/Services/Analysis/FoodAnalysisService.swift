import SwiftUI

/// A service to communicate with the backend Cloud Function for food analysis.
class FoodAnalysisService {
    
    // --- CONFIGURATION ---
    private let analysisFunctionURLString = "https://us-central1-foodjar-462805.cloudfunctions.net/analyze_food"
    private let userProfileService = UserProfileService()
    
    // Custom error type for more specific error handling.
    enum AnalysisError: Error {
        case invalidURL
        case networkError(Error)
        case httpError(statusCode: Int)
        case decodingError(Error)
        case noData
    }
    
    
    /// Sends an image to the Cloud Function for analysis using modern async/await.
    /// - Parameter image: The `UIImage` of the sticker to analyze.
    /// - Parameter isSpecial: A flag indicating if a creative prompt should be used.
    /// - Returns: A `Result` containing either the decoded `FoodInfo` or an `AnalysisError`.
    func analyzeFoodImage(_ image: UIImage, isSpecial: Bool) async -> Result<FoodInfo, AnalysisError> {
        await withCheckedContinuation { continuation in
            analyzeFoodImage(image, isSpecial: isSpecial) { result in
                continuation.resume(returning: result)
            }
        }
    }
    
    /// Sends an image to the Cloud Function for analysis.
    /// - Parameters:
    ///   - image: The `UIImage` of the sticker to analyze.
    ///   - isSpecial: A flag indicating if a creative prompt should be used.
    ///   - completion: A closure that returns a `Result` containing either the decoded `FoodInfo` or an `AnalysisError`.
    func analyzeFoodImage(_ image: UIImage, isSpecial: Bool, completion: @escaping (Result<FoodInfo, AnalysisError>) -> Void) {
        guard let url = URL(string: analysisFunctionURLString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Convert the UIImage to base64-encoded data.
        guard let imageData = image.pngData()?.base64EncodedString() else {
            completion(.failure(.decodingError(NSError(domain: "ImageEncoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image to base64"]))))
            return
        }
        
        // Load the user's profile to personalize the request.
        let profile = userProfileService.loadProfile()
        
        // Prepare the user profile payload if it exists.
        var userProfilePayload: [String: Any]?
        if let profile = profile {
            userProfilePayload = [
                "name": profile.name,
                "age": profile.age,
                "pronoun": profile.pronoun
            ]
        }
        
        // Prepare the main JSON payload.
        var payload: [String: Any] = [
            "image_data": imageData,
            "is_special": isSpecial
        ]
        
        // Add the user profile to the payload if available.
        payload["user_profile"] = userProfilePayload
        
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            completion(.failure(.decodingError(NSError(domain: "JSONEncoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create JSON body"]))))
            return
        }
        
        // Configure the network request.
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Execute the request.
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(.networkError(error)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(.networkError(NSError(domain: "ResponseError", code: 0, userInfo: nil))))
                return
            }
            
            guard (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(.httpError(statusCode: httpResponse.statusCode)))
                return
            }
            
            guard let data = data else {
                completion(.failure(.noData))
                return
            }
            
            // --- ADDED: Log the raw JSON response for debugging ---
            if let jsonString = String(data: data, encoding: .utf8) {
                print("Received JSON response:\n\(jsonString)")
            }
            
            // Decode the JSON response into our FoodInfo struct.
            do {
                let foodInfo = try JSONDecoder().decode(FoodInfo.self, from: data)
                completion(.success(foodInfo))
            } catch {
                print("❌ FoodAnalysisService: Failed to decode FoodInfo.")
                if let decodingError = error as? DecodingError {
                    print("   - Decoding Error: \(decodingError)")
                }
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
} 