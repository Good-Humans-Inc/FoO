import Foundation

/// A simple struct to hold the user's profile data for local storage.
/// It's Codable to allow easy saving to and loading from UserDefaults.
struct UserProfile: Codable {
    let name: String
    let age: Int
    let pronoun: String
    let goals: [String]
    // We can add goals here later if needed for personalization.
}

/// A service dedicated to managing the user's profile data locally.
/// This provides a fast, offline-first way to access user info for personalization.
class UserProfileService {
    
    /// A unique key to identify the saved profile data in UserDefaults.
    private let userProfileKey = "com.FoodStickerJarApp.userProfile"
    
    /// Saves the user's profile to UserDefaults.
    ///
    /// This method encodes the `UserProfile` object to JSON data and stores it
    /// locally. This should be called after a successful onboarding or profile update.
    /// - Parameter profile: The `UserProfile` object to save.
    func saveProfile(_ profile: UserProfile) {
        do {
            let data = try JSONEncoder().encode(profile)
            UserDefaults.standard.set(data, forKey: userProfileKey)
            print("✅ UserProfileService: Successfully saved profile to UserDefaults.")
        } catch {
            print("❌ UserProfileService: Failed to encode or save profile - \(error.localizedDescription)")
        }
    }
    
    /// Loads the user's profile from UserDefaults.
    ///
    /// This is the primary method for retrieving the user's profile data throughout the app.
    /// It returns `nil` if no profile has been saved yet.
    /// - Returns: A `UserProfile` object if one is found, otherwise `nil`.
    func loadProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
            print("ℹ️ UserProfileService: No profile found in UserDefaults. This is expected on first launch.")
            return nil
        }
        
        do {
            let profile = try JSONDecoder().decode(UserProfile.self, from: data)
            print("✅ UserProfileService: Successfully loaded profile from UserDefaults.")
            return profile
        } catch {
            print("❌ UserProfileService: Failed to decode profile from UserDefaults - \(error.localizedDescription)")
            return nil
        }
    }
} 