import Foundation

/// A service responsible for persisting and loading `FoodItem` data from the device's local storage.
class PersistenceService {
    
    // The URL for the file where we'll store our data.
    private var dataURL: URL
    
    init() {
        // Find the user's documents directory and create a file URL within it.
        // This is the standard location for storing user-generated data.
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        self.dataURL = urls[0].appendingPathComponent("FoodStickers.json")
    }
    
    /// Saves an array of FoodItem objects to a JSON file.
    /// - Parameter items: The array of `FoodItem` to save.
    func save(items: [FoodItem]) {
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
    
    /// Loads and decodes an array of FoodItem objects from the JSON file.
    /// - Returns: An array of `FoodItem`, or an empty array if the file doesn't exist or fails to decode.
    func load() -> [FoodItem] {
        do {
            // Try to read the data from our file URL.
            let data = try Data(contentsOf: dataURL)
            // Use JSONDecoder to convert the JSON data back into an array of FoodItem.
            let items = try JSONDecoder().decode([FoodItem].self, from: data)
            return items
        } catch {
            // It's normal for this to fail the first time the app is run (the file doesn't exist yet).
            // In that case, or if decoding fails, we return an empty array.
            print("Could not load food items, returning empty array. Error: \(error.localizedDescription)")
            return []
        }
    }
}