import SwiftUI

/// A view modifier that applies an animated, rotating rainbow beam effect,
/// suitable for special or rare items. The effect's visibility and animation
/// are controlled by an `isActive` binding.
struct HolographicEffect: ViewModifier {
    
    /// A binding to control the visibility of the effect from the parent view.
    @Binding var isActive: Bool
    
    @State private var rotationAngle: Angle = .zero
    
    /// A vibrant, repeating array of pastel colors for the rainbow gradient.
    private let rainbowColors: [Color] = [
        Color(red: 255/255, green: 179/255, blue: 186/255), // Pastel Pink/Red
        Color(red: 255/255, green: 223/255, blue: 186/255), // Pastel Orange
        Color(red: 255/255, green: 255/255, blue: 186/255), // Pastel Yellow
        Color(red: 186/255, green: 255/255, blue: 201/255), // Pastel Green
        Color(red: 186/255, green: 225/255, blue: 255/255), // Pastel Blue
        Color(red: 204/255, green: 204/255, blue: 255/255)  // Pastel Purple
    ]
    
    /// The duration of one full rotation of the beams.
    let duration: TimeInterval
    
    func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    AngularGradient(
                        gradient: Gradient(colors: rainbowColors + rainbowColors),
                        center: .center
                    )
                    .blur(radius: 20)
                    .rotationEffect(rotationAngle)
                }
                // --- Blooming Effect ---
                // The effect scales up and fades in when activated,
                // and scales down and fades out when deactivated.
                .scaleEffect(isActive ? 3.0 : 0.1)
                .opacity(isActive ? 1 : 0)
                .allowsHitTesting(false)
            )
            .onAppear {
                // Start a repeating rotation animation.
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotationAngle = .degrees(360)
                }
            }
    }
}

extension View {
    /// A helper function to easily apply the rotating rainbow beam effect.
    /// - Parameters:
    ///   - isActive: A binding to control when the effect is visible.
    ///   - duration: The time it takes for the beams to complete one rotation.
    /// - Returns: A view with the holographic effect applied.
    func holographic(isActive: Binding<Bool>, duration: TimeInterval = 4.0) -> some View {
        self.modifier(HolographicEffect(isActive: isActive, duration: duration))
    }
} 