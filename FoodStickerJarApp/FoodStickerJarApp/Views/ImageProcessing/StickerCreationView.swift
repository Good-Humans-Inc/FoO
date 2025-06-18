import SwiftUI
import SpriteKit

struct StickerCreationView: View {
    
    @EnvironmentObject var viewModel: HomeViewModel
    
    // The images passed in from the previous step.
    var originalImage: UIImage
    var stickerImage: UIImage
    
    // The namespace for the hero animation.
    @Namespace var namespace
    
    // State to control the animation flow.
    private enum AnimationState {
        case preparing
        case animating
        case detailView
    }
    @State private var animationState: AnimationState = .preparing
    
    // The generated background image for the sparkle effect.
    @State private var backgroundImage: UIImage?
    // The scene for the sparkle effect, stored in state to prevent re-creation.
    @State private var sparkleScene: SparkleScene?

    var body: some View {
        ZStack {
            // Use a GeometryReader to get the container size for the scene.
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        prepareAnimation(size: geo.size)
                    }
            }

            Color.black.ignoresSafeArea()
                .opacity(animationState == .detailView ? 0 : 1)

            let _ = print("[StickerCreationView] Current animation state: \(animationState)")

            if animationState == .detailView {
                FoodDetailView(foodItem: $viewModel.newSticker, stickerImage: stickerImage, namespace: namespace)
                
            } else if animationState == .animating, let scene = sparkleScene, let bg = backgroundImage {
                // The sparkle animation is in progress.
                ZStack {
                    // 1. The sticker, which will stay visible and become the "hero"
                    Image(uiImage: stickerImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .matchedGeometryEffect(id: "sticker", in: namespace, isSource: true)
                        .frame(maxHeight: 350)
                    
                    // 2. The background, which will fade out
                    Image(uiImage: bg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 350)
                        .opacity(animationState == .animating ? 1 : 0)
                        .animation(.easeOut(duration: 0.5), value: animationState)
                    
                    // 3. The sparkle animation on top
                    SpriteView(scene: scene)
                        .opacity(animationState == .animating ? 1 : 0)
                        .animation(.easeIn(duration: 1.0), value: animationState)

                }
            } else {
                // The preparing state (or a fallback).
                ProgressView()
                    .tint(.white)
            }
        }
        .onDisappear {
            // This is the final step, called when the sheet is dismissed.
            print("[StickerCreationView] onDisappear triggered.")
        }
    }
    
    private func prepareAnimation(size: CGSize) {
        // Generate the background mask.
        self.backgroundImage = UIImage.createBackgroundMask(from: originalImage, subjectImage: stickerImage)
        print("[StickerCreationView] Background mask created. Success: \(backgroundImage != nil)")
        
        // If we fail to create the mask, skip to the end.
        if let bg = backgroundImage {
            // Create the scene once.
            self.sparkleScene = SparkleScene(size: size, background: bg) {
                // This completion is called when the sparkle animation ends.
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    print("[StickerCreationView] Sparkle animation finished. Switching to .detailView state.")
                    self.animationState = .detailView
                }
            }
            // Move to the animating state AFTER the scene is created.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 1.0)) {
                    print("[StickerCreationView] Switching to .animating state.")
                    self.animationState = .animating
                }
            }
        } else {
            print("[StickerCreationView] Mask creation failed. Skipping to detail view.")
            self.animationState = .detailView
        }
    }
} 
