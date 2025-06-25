import SwiftUI
import UIKit

extension Color {
    // MARK: - Brand Colors
    // Define the core brand colors as static UIColor properties.
    // This makes them reusable for creating dynamic, theme-adaptive colors.
    private static let jasCream = UIColor(red: 253/255, green: 249/255, blue: 240/255, alpha: 1.0)
    private static let jasPink = UIColor(red: 245/255, green: 178/255, blue: 194/255, alpha: 1.0)
    private static let jasDarkYellow = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1.0)

    // MARK: - Theme Colors
    // These colors are used consistently across the app, regardless of light or dark mode.
    
    /// The primary background color of the app.
    static let themeBackground = Color(jasCream)
    
    /// The primary accent color of the app.
    static let themeAccent = Color(jasPink)

    /// The primary text color, for high contrast against the background.
    static let textPrimary = Color.black
    
    /// The secondary text color, for less prominent text elements.
    static let textSecondary = Color.gray
    
    /// A color for text placed on an accent-colored background.
    static let textOnAccent = Color.white

    /// A color for special offer text, like savings percentages.
    static let specialOffer = Color(jasDarkYellow)
}