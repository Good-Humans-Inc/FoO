import SwiftUI

struct HomeView: View {
    // Access the shared ViewModel from the environment.
    @EnvironmentObject var viewModel: HomeViewModel
    
    // Manages the presentation of the image picker and cropper.
    @State private var showImageProcessingSheet = false

    /// A computed binding that serves as the single source of truth for presenting our cover.
    /// It prioritizes showing the `newSticker` if it exists, otherwise falls back to the `selectedFoodItem`.
    private var itemForCover: Binding<FoodItem?> {
        Binding(
            get: {
                // The getter is simple: prioritize the new sticker, otherwise use the selected one.
                viewModel.newSticker ?? viewModel.selectedFoodItem
            },
            set: { newValue in
                // The setter correctly updates the underlying source of truth.
                // When the cover is dismissed, SwiftUI sets this binding's value to nil.
                if viewModel.newSticker != nil {
                    viewModel.newSticker = newValue
                } else {
                    viewModel.selectedFoodItem = newValue
                }
            }
        )
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Background color matching the design.
            Color(red: 253/255, green: 249/255, blue: 240/255)
                .ignoresSafeArea()

            // Main content VStack
            VStack(spacing: 0) {
                // Top placeholder button
                HStack {
                    Spacer()
                    Button(action: {
                        // Placeholder action for the top button
                        print("Top button tapped!")
                    }) {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.black.opacity(0.4))
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.top, 5) // Give it a little space from the top edge

                GeometryReader { geo in
                    let jarVisualWidth: CGFloat = geo.size.width
                    // Make the jar taller by adjusting the aspect ratio multiplier
                    let jarVisualHeight: CGFloat = jarVisualWidth * 1.8
                    
                    let spriteViewWidth = jarVisualWidth * 0.78
                    let spriteViewHeight = jarVisualHeight * 0.72
                    let spriteViewSize = CGSize(width: spriteViewWidth, height: spriteViewHeight)

                    ZStack {
                        Image("glassJar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: jarVisualWidth, height: jarVisualHeight)

                        SpriteView(scene: viewModel.jarScene)
                            .frame(width: spriteViewSize.width, height: spriteViewSize.height)
                            .offset(y: 1)
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(y: -40) // Move the entire jar container up
                    .onAppear {
                        viewModel.setupScene(with: spriteViewSize)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Camera Button
            Button(action: {
                showImageProcessingSheet = true
            }) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black.opacity(0.6))
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .shadow(radius: 5)
            }
            .padding(.bottom, 100) // Position it above the feedback bar area
            
            // This overlay will appear on top of the whole view when saving.
            if viewModel.isSavingSticker {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ProgressView()
                            Text("Preparing Sticker...")
                                .font(.title2)
                                .foregroundColor(.white)
                        }
                    }
            }
        }
        // MARK: - Sheet Modifiers
        .sheet(isPresented: $showImageProcessingSheet) {
            ImageProcessingView { originalImage, stickerImage in
                // The processing view is done. We have the image.
                showImageProcessingSheet = false // Dismiss the sheet...
                
                // Now, kick off the robust, parallel save and analysis process.
                Task {
                    await viewModel.processNewSticker(originalImage: originalImage, stickerImage: stickerImage)
                }
            }
        }
        
        // A single, unified full-screen cover for presenting the detail view.
        .fullScreenCover(item: itemForCover, onDismiss: {
            // After the cover is dismissed, ask the view model to commit the new
            // sticker if one exists. This handles the drop-in-jar animation.
            viewModel.commitNewStickerIfNecessary()
        }) { _ in
            // Pass the single source-of-truth binding to the detail view.
            FoodDetailView(foodItem: itemForCover)
        }
        // An alert to show if the saving process fails.
        .alert("Failed to Save Sticker", isPresented: .constant(viewModel.stickerCreationError != nil)) {
            Button("OK") { viewModel.stickerCreationError = nil }
        } message: {
            Text(viewModel.stickerCreationError ?? "An unknown error occurred. Please check your internet connection and try again.")
        }
    }
}
