import Foundation
import SwiftUI

/// A centralized place for application-wide constants and configuration values.
struct AppConfig {
    
    /// The primary brand color, extracted from the "Jas" logo.
    static let brandOrange = Color(red: 236/255, green: 138/255, blue: 83/255)
    
    /// The probability (from 0.0 to 1.0) that a newly created sticker will be "special".
    /// This affects both the visual treatment (e.g., holographic border) and the
    /// potential for extra content or stories.
    static let specialItemProbability: Double = 0.5 // temp for debugging
    
} 