import SwiftUI

struct HomeView: View {
    // Access the shared ViewModel from the environment.
    @EnvironmentObject var viewModel: HomeViewModel
    
    // Manages the presentation of the entire image processing flow.
    @State private var showImageProcessingSheet = false

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
                    let jarVisualWidth: CGFloat = geo.size.width * 0.9
                    let jarVisualHeight: CGFloat = jarVisualWidth * 1.35
                    let spriteViewSize = CGSize(width: jarVisualWidth * 0.8, height: jarVisualHeight * 0.75)

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
                            .offset(y: 15)
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
        // MARK: - Sheet Modifier
        
        // This single sheet manages the entire flow from camera to final sticker.
        .sheet(isPresented: $showImageProcessingSheet) {
            ImageProcessingView { finalStickerImage in
                // This is the final step. Add the sticker and dismiss the sheet.
                viewModel.addNewSticker(stickerImage: finalStickerImage)
                showImageProcessingSheet = false
            }
        }
        
        // Full screen cover for showing the sticker detail.
        .fullScreenCover(item: $viewModel.selectedFoodItem) { item in
            FoodDetailView(foodItem: item)
        }
    }
}
