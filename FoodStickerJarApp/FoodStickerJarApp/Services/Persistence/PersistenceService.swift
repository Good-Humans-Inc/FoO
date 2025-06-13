import Foundation

/// A service responsible for persisting and loading `FoodItem` data from the device's local storage.
/// This service is user-specific, storing data in a sub-directory named after the user's UID.
class PersistenceService {
    
    // The URL for the file where we'll store our data.
    private var dataURL: URL?
    
    /// Initializes the service for a specific user.
    /// - Parameter uid: The unique identifier for the user.
    init(uid: String?) {
        guard let uid = uid, !uid.isEmpty else {
            print("PersistenceService initialized without a UID. Data will not be saved or loaded.")
            return
        }
        
        // Find the user's documents directory.
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // Create a user-specific directory to store their data.
        let userDirectory = documentsDirectory.appendingPathComponent(uid)
        
        // Create the directory if it doesn't exist.
        if !FileManager.default.fileExists(atPath: userDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: userDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Error creating user directory: \(error.localizedDescription)")
                return
            }
        }
        
        // The final URL points to a JSON file inside the user's private directory.
        self.dataURL = userDirectory.appendingPathComponent("FoodStickers.json")
    }
    
    /// Saves an array of FoodItem objects to a JSON file.
    /// - Parameter items: The array of `FoodItem` to save.
    func save(items: [FoodItem]) {
        // Ensure we have a valid URL before trying to save.
        guard let dataURL = dataURL else {
            print("Cannot save: dataURL is nil.")
            return
        }
        
        // Run the save operation on a background thread to avoid blocking the UI.
        DispatchQueue.global(qos: .background).async {
            do {
                // Use JSONEncoder to convert the array of items into JSON data.
                let data = try JSONEncoder().encode(items)
                // Write the data to our file URL.
                try data.write(to: dataURL, options: .atomic)
            } catch {
                // If anything goes wrong, print an error.
                print("Error saving food items: \(error.localizedDescription)")
            }
        }
    }
    
    /// Loads and decodes an array of FoodItem objects from the JSON file.
    /// - Returns: An array of `FoodItem`, or an empty array if the file doesn't exist or fails to decode.
    func load() -> [FoodItem] {
        // Ensure we have a valid URL before trying to load.
        guard let dataURL = dataURL else {
            print("Cannot load: dataURL is nil.")
            return []
        }
        
        do {
            // Try to read the data from our file URL.
            let data = try Data(contentsOf: dataURL)
            // Use JSONDecoder to convert the JSON data back into an array of FoodItem.
            let items = try JSONDecoder().decode([FoodItem].self, from: data)
            return items
        } catch {
            // It's normal for this to fail the first time the app is run (the file doesn't exist yet).
            // In that case, or if decoding fails, we return an empty array.
            print("Could not load food items for UID, returning empty array. This is normal on first launch for a user.")
            return []
        }
    }
}