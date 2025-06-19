import SwiftUI

// A struct to decode the JSON response from the special content function.
/* This is no longer needed as the main analysis function handles both cases.
private struct SpecialContentResponse: Codable {
    let specialContent: String
    
    enum CodingKeys: String, CodingKey {
        case specialContent = "special_content"
    }
}
*/

/// A service to communicate with the backend Cloud Function for food analysis.
class FoodAnalysisService {
    
    // --- CONFIGURATION ---
    // IMPORTANT: Replace this with the trigger URL for your DEPLOYED `analyze_food` Cloud Function.
    private let analysisFunctionURLString = "https://us-central1-foodjar-462805.cloudfunctions.net/analyze_food"
    // The special content function is now deprecated.
    // private let specialContentFunctionURLString = "https://us-central1-foodjar-462805.cloudfunctions.net/generate_special_content"
    
    // Custom error type for more specific error handling.
    enum AnalysisError: Error {
        case invalidURL
        case networkError(Error)
        case httpError(statusCode: Int)
        case decodingError(Error)
        case noData
    }
    
    // This function is now deprecated in favor of the unified analysis call.
    /*
    /// Fetches a whimsical story for a special food item from the backend.
    /// - Parameter foodName: The name of the food to get a story for.
    /// - Returns: A `Result` containing either the story `String` or an `AnalysisError`.
    func fetchSpecialContent(for foodName: String) async -> Result<String, AnalysisError> {
        guard let url = URL(string: specialContentFunctionURLString) else {
            return .failure(.invalidURL)
        }

        let payload = ["name": foodName]
        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            return .failure(.decodingError(NSError(domain: "JSONEncoding", code: 0, userInfo: nil)))
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = httpBody
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                return .failure(.httpError(statusCode: statusCode))
            }
            
            let decodedResponse = try JSONDecoder().decode(SpecialContentResponse.self, from: data)
            return .success(decodedResponse.specialContent)

        } catch {
            if let decodingError = error as? DecodingError {
                return .failure(.decodingError(decodingError))
            } else {
                return .failure(.networkError(error))
            }
        }
    }
    */
    
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
        
        // Prepare the JSON payload, now including the 'is_special' flag.
        let payload: [String: Any] = [
            "image_data": imageData,
            "is_special": isSpecial
        ]
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