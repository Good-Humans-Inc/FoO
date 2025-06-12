import SwiftUI

/// A view that displays a single `FoodItem` image in a full-screen modal interface.
struct FoodDetailView: View {
    
    // The food item to be displayed. This is passed in when the view is created.
    let foodItem: FoodItem
    
    // An environment value that allows us to programmatically dismiss the view.
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack(alignment: .topTrailing) {
            // A semi-transparent black background to dim the underlying view.
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    // Tapping the background will dismiss the view.
                    dismiss()
                }

            // Display the sticker's image if it can be successfully created from the data.
            if let image = foodItem.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    // Add significant padding to ensure the image doesn't touch the screen edges.
                    .padding(40)
            } else {
                // A fallback view in case the image data is invalid.
                Text("Could not load image")
                    .foregroundColor(.white)
            }

            // A clearly visible close button in the top-right corner.
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.largeTitle)
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
    }
}