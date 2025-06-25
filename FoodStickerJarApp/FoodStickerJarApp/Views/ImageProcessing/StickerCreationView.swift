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
        case holographic
        case animating
        case detailView
    }
    @State private var animationState: AnimationState = .preparing
    
    // Controls the sticker's fade-in animation.
    @State private var stickerOpacity: Double = 0.0
    // Controls the blooming holographic background effect.
    @State private var showHolographicEffect = false
    
    // The generated background image for the sparkle effect.
    @State private var backgroundImage: UIImage?
    // The scene for the sparkle effect, stored in state to prevent re-creation.
    @State private var sparkleScene: SparkleScene?
    // The haptic feedback manager.
    @State private var hapticManager = HapticManager()

    var body: some View {
        ZStack {
            // Use a GeometryReader to get the container size for the scene.
            GeometryReader { geo in
                Color.clear
                    .onAppear {
                        prepareAnimation(size: geo.size)
                    }
            }

            Color.themeBackground.ignoresSafeArea()
                .opacity(animationState == .detailView ? 0 : 1)

            let _ = print("[StickerCreationView] Current animation state: \(animationState)")

            if animationState == .detailView {
                FoodDetailView(foodItem: .constant(viewModel.newSticker), stickerImage: stickerImage, namespace: namespace, isNewlyCreated: true)
                
            } else if animationState == .holographic {
                // For special items, show the sticker fading in over a
                // background with the holographic shine effect.
                ZStack {
                    // The background that receives the holographic effect.
                    // By applying the effect to a clear Rectangle that ignores
                    // the safe area, we ensure it covers the entire screen.
                    Rectangle()
                        .fill(Color.clear)
                        .holographic(isActive: $showHolographicEffect, duration: 4.0)
                        .ignoresSafeArea()

                    // The sticker itself, which fades in.
                    Image(uiImage: stickerImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .matchedGeometryEffect(id: "sticker", in: namespace, isSource: true)
                        .frame(maxHeight: 350)
                        .opacity(stickerOpacity)
                }
                .onAppear {
                    // Trigger the fade-in animation.
                    withAnimation(.easeIn(duration: 0.8)) {
                        stickerOpacity = 1.0
                    }
                }
                
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
                    .tint(.textPrimary)
            }
        }
        .onDisappear {
            // This is the final step, called when the sheet is dismissed.
            // This is the correct and reliable place to commit the sticker.
            print("➡️ [StickerCreationView] View disappeared. Triggering dismissal handler.")
            viewModel.handleStickerCreationDismissal()
        }
    }
    
    private func prepareAnimation(size: CGSize) {
        // Generate the background mask.
        self.backgroundImage = UIImage.createBackgroundMask(from: originalImage, subjectImage: stickerImage)
        print("[StickerCreationView] Background mask created. Success: \(backgroundImage != nil)")
        
        // If we fail to create the mask, skip to the end.
        if let bg = backgroundImage {
            // Check if the new sticker is special. Default to 'false' if it's somehow nil.
            let isSpecial = viewModel.newSticker?.isSpecial ?? false
            print("[StickerCreationView] Preparing animation. Sticker is special: \(isSpecial)")
            
            // Create the scene that will be used for the sparkle animation.
            self.sparkleScene = SparkleScene(size: size, background: bg, isSpecial: isSpecial) {
                // This completion is called when the sparkle animation ends.
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    print("[StickerCreationView] Sparkle animation finished. Switching to .detailView state.")
                    self.animationState = .detailView
                }
            }

            // --- Animation Flow Control ---
            if isSpecial {
                // For special items, start with the holographic effect.
                print("[StickerCreationView] Taking SPECIAL animation path.")
                self.animationState = .holographic
                
                // After a brief moment, trigger the bloom-in animations.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    hapticManager?.playSpecialReveal()
                    
                    // The sticker's fade-in is delayed slightly to let the
                    // bloom effect start first, creating a "reveal" effect.
                    withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                        self.stickerOpacity = 1.0
                    }
                    
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        self.showHolographicEffect = true
                    }
                }
                
                // After the effect plays, trigger the bloom-out and transition.
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { // Total duration
                    // First, bloom out the background effect.
                    withAnimation(.easeOut(duration: 0.5)) {
                        self.showHolographicEffect = false
                    }
                    
                    // Then, after the bloom-out starts, transition to the detail view.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            self.animationState = .detailView
                        }
                    }
                }
            } else {
                // For normal items, go directly to the sparkle animation.
                print("[StickerCreationView] Taking NORMAL animation path.")
                DispatchQueue.main.async {
                    withAnimation(.easeInOut(duration: 1.0)) {
                        self.animationState = .animating
                    }
                }
            }
        } else {
            print("[StickerCreationView] Mask creation failed. Skipping to detail view.")
            self.animationState = .detailView
        }
    }
} 
