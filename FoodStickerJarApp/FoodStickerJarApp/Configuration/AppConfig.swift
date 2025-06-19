import Foundation

/// A centralized place for application-wide constants and configuration values.
struct AppConfig {
    
    /// The probability (from 0.0 to 1.0) that a newly created sticker will be "special".
    /// This affects both the visual treatment (e.g., holographic border) and the
    /// potential for extra content or stories.
    static let specialItemProbability: Double = 1.0 // temp for debugging
    
} 