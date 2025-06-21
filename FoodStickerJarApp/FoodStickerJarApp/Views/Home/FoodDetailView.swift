import SwiftUI
import Kingfisher

/// A card-like view that displays the details of a single `FoodItem`.
/// It shows the full-resolution sticker, its name, and fun facts.
/// It's designed to be used in a sheet or full-screen cover.
struct FoodDetailView: View {
    @Binding var foodItem: FoodItem?
    
    // The generated sticker image, passed in for the hero animation.
    var stickerImage: UIImage?
    // The namespace for the hero animation. Made optional for reuse.
    var namespace: Namespace.ID?
    // Controls whether the fun fact typewriter animation should play.
    var isNewlyCreated: Bool = false
    
    @Environment(\.dismiss) var dismiss
    
    @State private var showContent = false
    @State private var animatedFunFact: String = "" // State for the typewriter animation
    
    // A static, efficient array of messages for unidentifiable items.
    private static let unidentifiableMessages = [
        "You better not eat that.",
        "Let's not feed this to anyone.",
        "Might be food. Might be art.",
        "It's a mystery.",
        "Calories: undefined. Courage: required.",
        "Chef, we have a situation.",
        "On a scale of 1 to food, this is a 0.",
        "Could be delicious...if you're an alien.",
        "Hopefully you have not ingested this.",
        "Blink twice if you need help.",
        "Let's call this one \"Abstract Cuisine\".",
        "Is it cake?",
        "The plot thickens...",
        "This looks like it has a backstory.",
        "Best served... on a shelf.",
    ]
    
    // Use @State to select a random message once and keep it stable.
    @State private var randomNotFoodMessage: String = unidentifiableMessages.randomElement() ?? "You better not eat that."
    
    var body: some View {
        // This guard makes the view crash-proof. If the binding becomes nil
        // during a dismiss animation, it shows an empty view instead of crashing.
        if let foodItem = foodItem {
            VStack(spacing: 0) {
                // Header with a close button on the right
                HStack {
                    Text(foodItem.creationDate, format: .dateTime.month(.abbreviated).day().hour().minute())
                        .font(.system(size: 16, weight: .light, design: .rounded))
                        .foregroundColor(.secondary)

                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle.weight(.light))
                            .foregroundColor(.gray.opacity(0.8))
                    }
                }
                .padding([.top, .horizontal])
                
                ScrollView {
                    VStack {
                        // Sticker Image
                        Group {
                            if let stickerImage = stickerImage {
                                // If a local UIImage is passed, use it directly for the transition.
                                Image(uiImage: stickerImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .matchedGeometryEffect(id: "sticker", in: namespace!)
                                
                            } else if let imageURL = URL(string: foodItem.imageURLString) {
                                KFImage(imageURL)
                                    .resizable()
                                    .placeholder {
                                        // Show a placeholder while the image is loading
                                        Text("(っ˘ω˘ς) loading...")
                                            .font(.headline)
                                            .fontWeight(.light)
                                            .foregroundColor(.secondary)
                                    }
                                    .if(namespace != nil) { view in
                                        view.matchedGeometryEffect(id: "sticker", in: namespace!)
                                    }
                            } else {
                                // Show a placeholder if the image data is invalid
                                Text("(っ˘ω˘ς) loading...")
                                    .font(.headline)
                                    .fontWeight(.light)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 350)
                        .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 20)

                        // Info Section
                        VStack(spacing: 16) {
                            // Name and Date
                            VStack {
                                if let name = foodItem.name {
                                    Text(name)
                                        .font(.system(size: 32, weight: .bold, design: .serif))
                                } else {
                                    // Show a loading/analyzing state
                                    Text("Casting spell...")
                                        .font(.system(size: 24, weight: .semibold, design: .serif))
                                }
                            }
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                            
                            Divider()
                            
                            // Details
                            // Prioritize showing the fun fact if it exists and is not "N/A".
                            if let funFact = foodItem.funFact, !funFact.isEmpty, funFact != "???", funFact != "N/A" {
                                Text(animatedFunFact.isEmpty ? " " : animatedFunFact) // Use a space to reserve height, preventing layout jumps
                                    .font(.custom("Georgia", size: 17))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top)
                                    .task(id: showContent) {
                                        guard showContent else { return }

                                        // Only animate if it's a newly created item.
                                        if isNewlyCreated {
                                            // Animate character-by-character for the classic typing effect.
                                            for char in funFact {
                                                // A short delay between each character.
                                                try? await Task.sleep(nanoseconds: 30_000_000) // 30ms
                                                
                                                // Ensure the task wasn't cancelled (e.g., view was dismissed).
                                                if !Task.isCancelled {
                                                    animatedFunFact.append(char)
                                                }
                                            }
                                        } else {
                                            // If it's not new, just show the full text immediately.
                                            animatedFunFact = funFact
                                        }
                                    }
                            }
                            // If the item is confirmed not food and there's no fun fact, show a random message.
                            else if foodItem.isFood == false {
                                Text(randomNotFoodMessage)
                                    .font(.custom("Georgia", size: 17))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .padding(.top)
                            }
                            // Otherwise, it's still loading.
                            else {
                                ProgressView()
                                    .padding(.top)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom) // Add some space at the very end of the scrollable content
                        .opacity(showContent ? 1 : 0)
                        .animation(.easeIn(duration: 0.3).delay(0.5), value: showContent)
                    }
                }
            }
            .background(
                // The background Group allows the .ignoresSafeArea() modifier to apply
                // only to the background gradients, not the VStack containing the content.
                Group {
                    // Use a different background for special items.
                    if foodItem.isSpecial == true {
                        LinearGradient(gradient: Gradient(colors: [Color(red: 1.0, green: 0.98, blue: 0.85), Color(red: 1.0, green: 0.9, blue: 0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    } else {
                        LinearGradient(gradient: Gradient(colors: [Color(.systemGray6)]), startPoint: .top, endPoint: .bottom)
                    }
                }
                .ignoresSafeArea()
            )
            .onAppear {
                // Always reset the animation text when the view appears.
                animatedFunFact = ""
                
                // If this view is part of a hero transition, delay the content appearance.
                if namespace != nil {
                    // This delay allows the matchedGeometryEffect to complete.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        showContent = true
                    }
                } else {
                    // If it's just being presented normally, show content immediately.
                    showContent = true
                }
            }
        } else {
            // This ProgressView is shown if the item becomes nil, preventing the crash.
            ProgressView()
        }
    }
}

/// A helper view for displaying a row of information in the card.
private struct InfoRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(content)
                .font(.custom("Georgia", size: 17))
                .foregroundColor(.primary)
        }
    }
}

// Helper to conditionally apply a modifier
extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
} 
