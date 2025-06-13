import SwiftUI

struct FoodDetailView: View {
    let foodItem: FoodItem
    
    // The service to load the full-resolution image.
    private let persistenceService = PersistenceService()
    
    // State to hold the full-resolution image once it's loaded.
    @State private var fullImage: UIImage?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        // Main container with a light gray background
        VStack(spacing: 0) {
            // Header with a close button on the right
            HStack {
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.largeTitle.weight(.light))
                        .foregroundColor(.gray.opacity(0.8))
                }
            }
            .padding([.top, .horizontal])
            
            // Sticker Image
            Image(uiImage: fullImage ?? foodItem.thumbnailImage ?? UIImage())
                 .resizable()
                 .aspectRatio(contentMode: .fit)
                 .frame(maxHeight: 350)
                 .shadow(color: .black.opacity(0.2), radius: 15, y: 10)
                 .padding(.horizontal, 40)
                 .padding(.bottom, 20)

            // Info Section
            VStack(spacing: 16) {
                // Name and Date
                VStack {
                    if let name = foodItem.name, name != "N/A" {
                        Text(name)
                            .font(.system(size: 32, weight: .bold, design: .serif))
                        
                        Text(foodItem.creationDate, style: .date)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                    } else if foodItem.name == "N/A" {
                        Text("Not a Food Item")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                        
                    } else {
                        // Show a loading/analyzing state
                        Text("Analyzing...")
                            .font(.system(size: 24, weight: .semibold, design: .serif))
                    }
                }
                .multilineTextAlignment(.center)
                .padding(.bottom, 10)
                
                Divider()
                
                // Details
                if let name = foodItem.name, name != "N/A" {
                    InfoRow(title: "Fun Fact", content: foodItem.funFact ?? "...")
                    InfoRow(title: "Nutrition", content: foodItem.nutrition ?? "...")
                } else if foodItem.name == "N/A" {
                    Text("We couldn't identify this as a food item. Please try again with another delicious dish!")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                } else {
                    ProgressView()
                        .padding(.top)
                }
            }
            .padding(.horizontal, 30)
            
            Spacer()
        }
        .background(Color(.systemGray6).ignoresSafeArea())
        .onAppear {
            // Asynchronously load the full-resolution image when the view appears.
            fullImage = persistenceService.loadImage(for: foodItem.id)
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