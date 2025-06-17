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
        ZStack {
            // Background color matching the design.
            Color(red: 253/255, green: 249/255, blue: 240/255)
                .ignoresSafeArea()

            VStack(spacing: 12) {
                Spacer().frame(height: 20)

                Text("Shake your phone!")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.top)

                GeometryReader { geo in
                    // Make the jar visual fill the width of the screen for a larger appearance.
                    let jarVisualWidth: CGFloat = geo.size.width
                    let jarVisualHeight: CGFloat = jarVisualWidth * 1.35
                    
                    // Adjust the physics world to fit snugly inside the new, larger jar image.
                    // These values are fine-tuned to align with the transparent interior of the asset.
                    let spriteViewWidth = jarVisualWidth * 0.78
                    let spriteViewHeight = jarVisualHeight * 0.72
                    let spriteViewSize = CGSize(width: spriteViewWidth, height: spriteViewHeight)

                    // This ZStack is now directly inside the GeometryReader.
                    // It will center itself, and its size is determined by its content,
                    // preventing it from blocking the button below.
                    ZStack {
                        Image("glassJar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: jarVisualWidth, height: jarVisualHeight)

                        SpriteView(scene: viewModel.jarScene)
                            .frame(width: spriteViewSize.width, height: spriteViewSize.height)
                            .offset(y: 15) // A slight vertical offset for perfect alignment.
                    }
                    // Place the frame modifier on the ZStack to center it.
                    .frame(width: geo.size.width, height: geo.size.height)
                    .onAppear {
                        // Now that the view has appeared and has a size, set up the scene.
                        viewModel.setupScene(with: spriteViewSize)
                    }
                }

                Spacer()

                Button(action: {
                    // Trigger the image processing sheet.
                    showImageProcessingSheet = true
                }) {
                    Text("Take Picture")
                        .font(.system(size: 18, weight: .semibold))
                        .padding()
                        .frame(minWidth: 240)
                        .background(Color(red: 236/255, green: 138/255, blue: 83/255))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.bottom, 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // This overlay will appear on top of the whole view when saving.
            if viewModel.isSavingSticker {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .overlay {
                        VStack {
                            ProgressView()
                            Text("( ˘▽˘)っ Making your sticker...")
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
