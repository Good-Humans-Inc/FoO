import SwiftUI
import VisionKit

/// This view coordinates the entire image capture and processing flow.
/// It presents the camera, and once an image is taken, it shows the
/// subject lifting UI for the user to confirm and save the sticker.
struct ImageProcessingView: View {
    
    // State for the different stages of the process.
    private enum ProcessingState {
        case camera
        case cropping(UIImage) // Holds the image taken from the camera
        case finished
    }
    
    // The current state of the processing flow.
    @State private var currentState: ProcessingState = .camera
    
    // The completion handler to call when a final sticker is created.
    var onComplete: (UIImage) -> Void
    
    // Environment value to programmatically dismiss the sheet.
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // A switch to show the correct view based on the current state.
        switch currentState {
        case .camera:
            CameraView { image in
                // When an image is picked, resize it and move to the cropping state.
                let resizedImage = image.resized(toMaxSize: 1024)
                currentState = .cropping(resizedImage)
            }
            .ignoresSafeArea()
            
        case .cropping(let image):
            // This view contains the VisionKit subject lifting logic.
            SubjectLiftContainerView(image: image) { finalSticker in
                // When the user saves the sticker, call the completion handler.
                onComplete(finalSticker)
                // Mark the process as finished to trigger dismissal.
                currentState = .finished
            }
            .ignoresSafeArea()
            
        case .finished:
            // An empty view, shown just before the sheet dismisses.
            EmptyView()
                .onAppear {
                    // Dismiss the sheet once we enter the finished state.
                    dismiss()
                }
        }
    }
}

/// A helper view that wraps the VisionKit subject lifting UI.
private struct SubjectLiftContainerView: View {
    let image: UIImage
    let onComplete: (UIImage) -> Void
    
    // The VisionKit interaction object.
    @State private var interaction = ImageAnalysisInteraction()
    // The state of the image analysis.
    @State private var analysisState: AnalysisState = .analyzing
    // The haptic feedback manager.
    @State private var hapticManager = HapticManager()
    
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
                switch analysisState {
                case .analyzing:
                    Text("Analyzing for food...")
                        .padding()
                        .background(.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                case .subjectsFound:
                    Text("Subject found! Creating your sticker...")
                        .padding()
                        .background(.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                case .noSubjectsFound:
                    Text("Couldn't find a subject. Please try another photo.")
                        .padding()
                        .multilineTextAlignment(.center)
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                Spacer()
                
                // Only show a button if the process fails. Otherwise, it's automatic.
                if analysisState == .noSubjectsFound {
                    Button("Try Again") { dismiss() }
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
                print("Starting image analysis...")
                let analysis = try await analyzer.analyze(image, configuration: config)
                interaction.analysis = analysis
                interaction.preferredInteractionTypes = .imageSubject
                print("Image analysis complete.")

                // A short delay might give the interaction time to fully process the analysis.
                try? await Task.sleep(for: .milliseconds(200))

                // Find the main subject
                guard let mainSubject = await interaction.subjects.first else {
                    print("Analysis finished, but no subjects were found.")
                    self.analysisState = .noSubjectsFound
                    return
                }
                
                print("Main subject found. Highlighting now.")
                interaction.highlightedSubjects = [mainSubject]
                self.analysisState = .subjectsFound
                hapticManager?.playRampUp()

                // Pause briefly so the user sees the highlight, then proceed automatically.
                print("Pausing for user to see the highlight effect...")
                try? await Task.sleep(for: .seconds(1.5))

                // Try to extract the subject image
                print("Attempting to extract subject image...")
                do {
                    let subjectImage = try await interaction.image(for: [mainSubject])
                    print("Subject image extracted. Applying sticker effect...")
                    
                    if let stickerImage = subjectImage.addingStickerOutline(width: 20, color: .white) {
                        print("Sticker created successfully. Completing process.")
                        onComplete(stickerImage)
                    } else {
                        print("Error: Failed to apply sticker outline.")
                        self.analysisState = .noSubjectsFound
                    }
                } catch {
                    print("Error: Failed to extract subject image. \(error.localizedDescription)")
                    self.analysisState = .noSubjectsFound
                }
            } catch {
                self.analysisState = .noSubjectsFound
                print("Image analysis failed: \(error.localizedDescription)")
            }
        }
    }
}
