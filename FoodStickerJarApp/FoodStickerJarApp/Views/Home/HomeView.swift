import SwiftUI

struct HomeView: View {
    // Access the shared ViewModel from the environment.
    @EnvironmentObject var viewModel: HomeViewModel
    
    // Manages the presentation of the image picker and cropper.
    @State private var showImageProcessingSheet = false

    // State for the new UI
    @State private var showFeedbackInput = false
    @State private var feedbackText = ""
    @State private var jarViewSize: CGSize = .zero
    
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
        NavigationView {
            ZStack {
                // Background color matching the design.
                Color(red: 253/255, green: 249/255, blue: 240/255)
                    .ignoresSafeArea()
                
                // Main content VStack
                VStack(spacing: 0) {
                    // Top bar with new buttons
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                // Toggle the feedback input view's visibility.
                                showFeedbackInput.toggle()
                            }
                        }) {
                            Image("logoIcon") // Make sure this asset exists
                                .resizable()
                                .scaledToFit()
                                .frame(width: 84, height: 84)
                                .clipShape(Circle())
                        }
                        
                        if showFeedbackInput {
                            // Custom Feedback Input Area
                            HStack(spacing: 12) {
                                TextField("Confused? Tell me about it...", text: $feedbackText)
                                    .textFieldStyle(.plain)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(.thinMaterial)
                                    .clipShape(Capsule())

                                Button(action: {
                                    viewModel.submitFeedback(feedbackText)
                                    withAnimation {
                                        showFeedbackInput = false
                                        feedbackText = ""
                                    }
                                }) {
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(feedbackText.isEmpty ? .gray : Color(red: 236/255, green: 138/255, blue: 83/255))
                                }
                                .disabled(feedbackText.isEmpty)
                            }
                            .padding(8)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 30, style: .continuous)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: feedbackText.isEmpty)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        // If user swipes from right to left, close the feedback box
                                        if value.translation.width > 50 {
                                            withAnimation {
                                                showFeedbackInput = false
                                            }
                                        }
                                    }
                            )
                        }
                        
                        Spacer()
                        
                        if !showFeedbackInput {
                            // Archive button
                            Button(action: {
                                viewModel.initiateArchiving()
                            }) {
                                Image(systemName: "archivebox.fill")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(Color(red: 236/255, green: 138/255, blue: 83/255))
                            }
                            .padding(.trailing, 10)
                            
                            NavigationLink(destination: ShelfView()) {
                                Image("shelfIcon") // Make sure this asset exists
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 84, height: 84)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5) // Give it a little space from the top edge
                    .frame(height: 90) // Give the top bar a fixed height
                    
                    GeometryReader { geo in
                        JarContainerView(jarScene: viewModel.jarScene, size: geo.size)
                            .frame(width: geo.size.width, height: geo.size.height)
                            .offset(y: -40) // Move the entire jar container up
                            .onAppear {
                                self.jarViewSize = geo.size
                                let spriteViewSize = CGSize(width: geo.size.width * 0.78, height: geo.size.width * 1.8 * 0.72)
                                viewModel.setupScene(with: spriteViewSize)
                            }
                            .onChange(of: geo.size) { newSize in
                                self.jarViewSize = newSize
                            }
                    }
                }
                .onChange(of: viewModel.triggerSnapshot) { shouldSnapshot in
                    if shouldSnapshot {
                        let snapshotView = JarContainerView(jarScene: viewModel.jarScene, size: jarViewSize)
                            .frame(width: jarViewSize.width, height: jarViewSize.height)
                            .offset(y: -40)
                            .background(Color(red: 253/255, green: 249/255, blue: 240/255))
                        
                        if let image = snapshotView.snapshot() {
                            Task {
                                await viewModel.archiveJar(with: image)
                            }
                        }
                        viewModel.triggerSnapshot = false
                    }
                }
                
                // Floating Camera Button - Centered
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }

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

                if viewModel.showArchiveInProgress {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            VStack {
                                ProgressView()
                                Text("Archiving Jar...")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                }
            }
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationViewStyle(.stack)
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
