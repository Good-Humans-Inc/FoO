import SwiftUI

struct HomeView: View {
    // Access the shared ViewModel from the environment.
    @EnvironmentObject var viewModel: HomeViewModel
    
    // Manages the presentation of the image picker and cropper.
    @State private var showImageProcessingSheet = false
    // Manages the presentation of the new sticker detail card.
    @State private var showNewStickerSheet = false

    /// A computed binding that serves as the single source of truth for presenting our cover.
    /// It prioritizes showing the `newSticker` if it exists, otherwise falls back to the `selectedFoodItem`.
    private var itemForCover: Binding<FoodItem?> {
        $viewModel.newSticker.wrappedValue != nil ? $viewModel.newSticker : $viewModel.selectedFoodItem
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
        }
        // MARK: - Sheet Modifiers
        
        // This sheet manages the image picking and cropping flow.
        .sheet(isPresented: $showImageProcessingSheet, onDismiss: {
            // When this sheet closes, if a new sticker was created, show the detail sheet.
            if viewModel.newSticker != nil {
                showNewStickerSheet = true
            }
        }) {
            ImageProcessingView { finalStickerImage in
                // This is the first step. Create the item and dismiss the cropper.
                viewModel.startStickerCreation(stickerImage: finalStickerImage)
                showImageProcessingSheet = false
            }
        }
        
        // This sheet shows the detail card for the newly created sticker.
        .sheet(isPresented: $showNewStickerSheet, onDismiss: {
            // When this sheet is dismissed, commit the new sticker to the jar.
            viewModel.commitNewSticker()
            // Reset the temporary sticker property.
            viewModel.newSticker = nil
        }) {
            // The detail view needs a binding. Because newSticker is an optional,
            // we create a binding that safely unwraps it.
            if let newStickerBinding = Binding($viewModel.newSticker) {
                FoodDetailView(foodItem: newStickerBinding)
            } else {
                // Failsafe view if the sheet appears without data.
                Text("Creating sticker...")
            }
        }
        
        // Full screen cover for showing the sticker detail from the jar.
        .fullScreenCover(item: $viewModel.selectedFoodItem) { selectedItem in
            // To create a binding for the detail view, we need to find the index
            // of the selected item in our source array.
            if let index = viewModel.foodItems.firstIndex(where: { $0.id == selectedItem.id }) {
                FoodDetailView(foodItem: $viewModel.foodItems[index])
            } else {
                // Failsafe in case the item can't be found.
                Text("Sticker not found")
            }
        }
    }
}
