import SwiftUI

extension Color {
    // MARK: - Logo Color Palette
    // Official colors from the Jas logo for future reference:
    // Warm Cream/Yellow: UIColor(red: 254.0/255.0, green: 248.0/255.0, blue: 208.0/255.0, alpha: 1.0)
    // Soft Pink: UIColor(red: 245.0/255.0, green: 178.0/255.0, blue: 194.0/255.0, alpha: 1.0)
    // Mint Green: UIColor(red: 179.0/255.0, green: 222.0/255.0, blue: 219.0/255.0, alpha: 1.0)
    // Teal: UIColor(red: 141.0/255.0, green: 198.0/255.0, blue: 198.0/255.0, alpha: 1.0)
    // Off-White: UIColor(red: 254.0/255.0, green: 255.0/255.0, blue: 254.0/255.0, alpha: 1.0)
    
    // MARK: - Theme Colors
    
    /// The primary brand color using the soft pink from the Jas logo.
    static let themeAccent = Color(red: 245/255, green: 178/255, blue: 194/255)
    
    /// Additional logo colors for future use
    static let logoWarmCream = Color(red: 254/255, green: 248/255, blue: 208/255)
    static let logoMintGreen = Color(red: 179/255, green: 222/255, blue: 219/255)
    static let logoTeal = Color(red: 141/255, green: 198/255, blue: 198/255)
    static let logoOffWhite = Color(red: 254/255, green: 255/255, blue: 254/255)
    
    /// The warm, off-white background color used across the app.
    static let themeBackground = Color(red: 253/255, green: 249/255, blue: 240/255)
} 