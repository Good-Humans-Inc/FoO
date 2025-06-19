import Foundation

/// A service dedicated to communicating with the backend to generate images.
final class ImageGenerationService {
    
    // The URL for the local or deployed image generation cloud function.
    // TODO: Replace with your deployed function URL.
    private let generationURL = URL(string: "http://localhost:8080")!

    enum GenerationError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case decodingError(Error)
        case serverError(String)
        case unknownError
        
        var errorDescription: String? {
            switch self {
            case .invalidURL: return "The server URL is invalid."
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            case .decodingError: return "Failed to decode the server's response."
            case .serverError(let message): return "Server error: \(message)"
            case .unknownError: return "An unknown error occurred."
            }
        }
    }
    
    /// Sends a prompt to the backend to generate a new sticker image.
    ///
    /// - Parameter prompt: The text prompt to be sent to the DALL-E model.
    /// - Returns: A `Result` containing either the URL of the generated image as a `String` or a `GenerationError`.
    func generateImage(with prompt: String) async -> Result<String, GenerationError> {
        var request = URLRequest(url: generationURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody = ["prompt": prompt]
        
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            return .failure(.decodingError(error))
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                return .failure(.unknownError)
            }
            
            // Decode the JSON response
            let decoder = JSONDecoder()
            if (200...299).contains(httpResponse.statusCode) {
                // Success
                if let responseJSON = try? decoder.decode([String: String].self, from: data),
                   let imageURL = responseJSON["generated_image_url"] {
                    return .success(imageURL)
                } else {
                    return .failure(.decodingError(URLError(.cannotParseResponse)))
                }
            } else {
                // Error from server
                if let errorJSON = try? decoder.decode([String: String].self, from: data),
                   let errorMessage = errorJSON["error"] {
                    return .failure(.serverError(errorMessage))
                } else {
                    return .failure(.unknownError)
                }
            }
        } catch {
            return .failure(.networkError(error))
        }
    }
} 