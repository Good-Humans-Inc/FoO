import SwiftUI

/// A service to communicate with the backend Cloud Function for food analysis.
class FoodAnalysisService {
    
    // --- CONFIGURATION ---
    // IMPORTANT: Replace this with the trigger URL for your deployed GCP Cloud Function.
    private let cloudFunctionURLString = "YOUR_GCP_FUNCTION_URL_HERE"
    
    // Custom error type for more specific error handling.
    enum AnalysisError: Error {
        case invalidURL
        case networkError(Error)
        case httpError(statusCode: Int)
        case decodingError(Error)
        case noData
    }
    
    /// Sends an image to the Cloud Function for analysis.
    /// - Parameters:
    ///   - image: The `UIImage` of the sticker to analyze.
    ///   - completion: A closure that returns a `Result` containing either the decoded `FoodInfo` or an `AnalysisError`.
    func analyzeFoodImage(_ image: UIImage, completion: @escaping (Result<FoodInfo, AnalysisError>) -> Void) {
        guard let url = URL(string: cloudFunctionURLString) else {
            completion(.failure(.invalidURL))
            return
        }
        
        // Convert the UIImage to base64-encoded data.
        guard let imageData = image.pngData()?.base64EncodedString() else {
            completion(.failure(.decodingError(NSError(domain: "ImageEncoding", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to encode image to base64"]))))
            return
        }
        
        // Prepare the JSON payload.
        let payload = ["image_data": imageData]
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
            
            // Decode the JSON response into our FoodInfo struct.
            do {
                let foodInfo = try JSONDecoder().decode(FoodInfo.self, from: data)
                completion(.success(foodInfo))
            } catch {
                completion(.failure(.decodingError(error)))
            }
        }.resume()
    }
} 