import SwiftUI
import Kingfisher

/// A card-like view that displays the details of a single `FoodItem`.
/// It shows the full-resolution sticker, its name, and fun facts.
/// It's designed to be used in a sheet or full-screen cover.
struct FoodDetailView: View {
    @Binding var foodItem: FoodItem?
    
    @Environment(\.dismiss) var dismiss
    
    // A static, efficient array of messages for unidentifiable items.
    private static let unidentifiableMessages = [
        "You better not eat that.",
        "Let's not feed this to anyone.",
        "Might be food. Might be art.",
        "It's a mystery.",
        "Calories: undefined. Courage: required.",
        "Chef, we have a situation.",
        "My algorithm is confused. And a little scared.",
        "On a scale of 1 to food, this is a 0.",
        "Could be delicious...if you're an alien.",
        "Hopefully you have not ingested this.",
        "Just to remind you this is your food jar, not your poison control center.",
        "Blink twice if you need help.",
        "For your safety, and mine, let's not.",
        "Debatable.",
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
                        .font(.system(size: 16, weight: .bold, design: .rounded))
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
                            if let imageURL = URL(string: foodItem.imageURLString) {
                                KFImage(imageURL)
                                    .resizable()
                                    .placeholder {
                                        // Show a placeholder while the image is loading
                                        Image(systemName: "photo")
                                            .resizable()
                                            .foregroundColor(.gray)
                                            .aspectRatio(contentMode: .fit)
                                    }
                            } else {
                                // Show a placeholder if the image data is invalid
                                Image(systemName: "photo")
                                    .resizable()
                                    .foregroundColor(.gray)
                            }
                        }
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 350)
                        .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
                        .padding(.horizontal, 40)
                        .padding(.bottom, 20)

                        // Info Section
                        VStack(spacing: 16) {
                            // Name and Date
                            VStack {
                                if let name = foodItem.name {
                                    Text(name)
                                        .font(.system(size: 32, weight: .bold, design: .serif))
                                } else {
                                    // Show a loading/analyzing state
                                    Text("Thinking...")
                                        .font(.system(size: 24, weight: .semibold, design: .serif))
                                }
                            }
                            .multilineTextAlignment(.center)
                            .padding(.bottom, 10)
                            
                            Divider()
                            
                            // Details
                            if foodItem.isFood == true {
                                // Case: It's a food item with full details.
                                if let funFact = foodItem.funFact, let nutrition = foodItem.nutrition,
                                   funFact != "N/A", nutrition != "N/A" {
                                    VStack(alignment: .leading, spacing: 16) {
                                        InfoRow(title: "Do you know?", content: funFact)
                                        InfoRow(title: "Nutrition", content: nutrition)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                } else {
                                    // This can happen if analysis is still processing for a food item.
                                    ProgressView()
                                        .padding(.top)
                                }
                            } else if foodItem.isFood == false {
                                // Case: Not a food item (or unidentifiable).
                                Text(randomNotFoodMessage)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.top)
                            } else {
                                // Case: Still loading (isFood is nil).
                                ProgressView()
                                    .padding(.top)
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.bottom) // Add some space at the very end of the scrollable content
                    }
                }
            }
            .background(Color(.systemGray6).ignoresSafeArea())
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
                .font(.body)
                .foregroundColor(.primary)
        }
    }
} 
