import SwiftUI
import VisionKit

/// This view coordinates the entire image capture and processing flow.
/// It presents the camera, and once an image is taken, it shows the
/// subject lifting UI for the user to confirm and save the sticker.
struct ImageProcessingView: View {
    
    @EnvironmentObject var viewModel: HomeViewModel
    
    // State for the different stages of the process.
    private enum ProcessingState {
        case camera
        case cropping(UIImage) // Holds the image taken from the camera
        case animating(original: UIImage, sticker: UIImage) // The new animation view
        case finished
    }
    
    // The current state of the processing flow.
    @State private var currentState: ProcessingState = .camera
    
    // Environment value to programmatically dismiss the sheet.
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // A switch to show the correct view based on the current state.
        let _ = print("[ImageProcessingView] Current state: \(currentState)")
        switch currentState {
        case .camera:
            CameraView { image in
                // By removing the resize step here, the user gets to crop the exact
                // image they saw in the camera preview.
                currentState = .cropping(image)
            }
            .ignoresSafeArea()
            
        case .cropping(let image):
            // This view contains the VisionKit subject lifting logic.
            SubjectLiftContainerView(image: image, onComplete: { finalSticker, isSpecial in
                
                // Immediately prepare the UI for the animation by creating a
                // temporary local FoodItem.
                let stickerID = viewModel.prepareForAnimation(isSpecial: isSpecial)
                
                // Immediately transition to the animation state so the user
                // sees the effect without waiting for the network.
                currentState = .animating(original: image, sticker: finalSticker)
                
                // Launch a detached background task to handle the slow work
                // of saving the images and data to the network.
                Task {
                    await viewModel.processNewSticker(id: stickerID, originalImage: image, stickerImage: finalSticker)
                }
            })
            .ignoresSafeArea()
            
        case .animating(let original, let sticker):
            let _ = print("[ImageProcessingView] Entering .animating state.")
            // Show our new sparkle and hero transition view
            StickerCreationView(originalImage: original, stickerImage: sticker)
            .environmentObject(viewModel)
            .ignoresSafeArea()
            
        case .finished:
            // This state is no longer used, but we'll keep it for now.
            EmptyView()
                .onAppear {
                    // Dismiss the sheet once we enter the finished state.
                    print("[ImageProcessingView] .finished state appeared. Dismissing sheet.")
                    dismiss()
                }
        }
    }
}

/// A helper view that wraps the VisionKit subject lifting UI.
private struct SubjectLiftContainerView: View {
    let image: UIImage
    let onComplete: (UIImage, Bool) -> Void
    
    // The VisionKit interaction object.
    @State private var interaction = ImageAnalysisInteraction()
    // The state of the image analysis.
    @State private var analysisState: AnalysisState = .analyzing
    // The haptic feedback manager.
    @State private var hapticManager = HapticManager()
    
    @EnvironmentObject var viewModel: HomeViewModel
    @Environment(\.dismiss) var dismiss
    
    enum AnalysisState {
        case analyzing
        case subjectsFound
        case noSubjectsFound
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            SubjectLiftView(image: image, interaction: interaction)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Overlay UI for instructions and buttons.
            VStack {
                // Instruction text based on the analysis state.
                Group {
                    switch analysisState {
                    case .analyzing:
                        Text("Taking a look ( •̀_•́)ノ")
                            .padding()
                            .background(.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    case .subjectsFound:
                        Text("Found it! (≧◡≦)♡")
                            .padding()
                            .background(.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    case .noSubjectsFound:
                        Text("Hmm... I'm lost ( •́‸•̀) Can you center the food and get a clear, close shot?")
                            .padding()
                            .multilineTextAlignment(.center)
                            .background(Color.red.opacity(0.8))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 60)
                
                Spacer()
                
                // Only show a button if the process fails. Otherwise, it's automatic.
                if analysisState == .noSubjectsFound {
                    Button("Try again!") { dismiss() }
                        .font(.custom("Georgia", size: 17))
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(10)
                        .padding()
                }
            }
        }
        .task {
            // Perform the image analysis when the view appears.
            let analyzer = ImageAnalyzer()
            let config = ImageAnalyzer.Configuration([.visualLookUp])
            do {
                print("[SubjectLift] Starting image analysis...")
                let analysis = try await analyzer.analyze(image, configuration: config)
                interaction.analysis = analysis
                interaction.preferredInteractionTypes = .imageSubject
                print("[SubjectLift] Image analysis complete.")

                // A short delay might give the interaction time to fully process the analysis.
                try? await Task.sleep(for: .milliseconds(200))

                // Find the main subject
                guard let mainSubject = await interaction.subjects.first else {
                    print("[SubjectLift] Analysis finished, but no subjects were found.")
                    self.analysisState = .noSubjectsFound
                    return
                }
                
                print("[SubjectLift] Main subject found. Highlighting now.")
                interaction.highlightedSubjects = [mainSubject]
                self.analysisState = .subjectsFound
                hapticManager?.playRampUp()

                // Pause briefly so the user sees the highlight, then proceed automatically.
                print("[SubjectLift] Pausing for 1.5s to show highlight...")
                try? await Task.sleep(for: .seconds(1.5))

                // Try to extract the subject image
                print("[SubjectLift] Attempting to extract subject image...")
                do {
                    let subjectImage = try await interaction.image(for: [mainSubject])
                    print("[SubjectLift] Subject image extracted. Applying sticker effect...")
                    
                    // Determine if the sticker is special right here, before creating the image.
                    let isSpecial = Double.random(in: 0...1) < AppConfig.specialItemProbability
                    print("[SubjectLift] Sticker is special: \(isSpecial)")
                    
                    // Use a wider border for special items to make them pop.
                    let borderWidth = isSpecial ? 90.0 : 60.0
                    
                    // Generate the sticker with the correct effect (white outline or rainbow glow).
                    if let stickerWithEffect = subjectImage.addingStickerEffect(width: borderWidth, isSpecial: isSpecial) {
                        let finalSticker = stickerWithEffect.resized(toMaxSize: 250)
                        print("[SubjectLift] Sticker created successfully. Calling onComplete.")
                        onComplete(finalSticker, isSpecial)
                    } else {
                        print("[SubjectLift] Error: Failed to apply sticker effect.")
                        self.analysisState = .noSubjectsFound
                    }
                } catch {
                    print("[SubjectLift] Error: Failed to extract subject image. \(error.localizedDescription)")
                    self.analysisState = .noSubjectsFound
                }
            } catch {
                self.analysisState = .noSubjectsFound
                print("[SubjectLift] Image analysis failed: \(error.localizedDescription)")
            }
        }
    }
}
