import SwiftUI

struct FoodDetailView: View {
    let foodItem: FoodItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Semi-transparent background
            Color.black.opacity(0.8).ignoresSafeArea()
                .onTapGesture { dismiss() }
            
            // The main card content
            VStack(spacing: 0) {
                // The sticker image
                if let image = foodItem.image {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: 300)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(maxWidth: .infinity, maxHeight: 300)
                        .overlay(Text("Image not available").foregroundColor(.white))
                }
                
                // The info panel
                VStack(alignment: .leading, spacing: 16) {
                    if let name = foodItem.name, name != "N/A" {
                        // Display the analyzed information
                        Text(name)
                            .font(.largeTitle.weight(.bold))
                            .foregroundColor(.primary)
                        
                        InfoRow(title: "Fun Fact", content: foodItem.funFact ?? "...")
                        InfoRow(title: "Nutrition", content: foodItem.nutrition ?? "...")
                        
                    } else if foodItem.name == "N/A" {
                        // Handle the case where the object was not identified as food
                         Text("Not Identified as Food")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("This doesn't appear to be a food item. Try taking a photo of something else!")
                            .foregroundColor(.secondary)

                    } else {
                        // Show a loading/analyzing state
                        Text("Analyzing...")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("Checking our digital cookbook for information on this item. This may take a moment.")
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(32)
            
            // Close Button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }
}

/// A helper view for displaying a row of information in the card.
private struct InfoRow: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            Text(content)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
} 