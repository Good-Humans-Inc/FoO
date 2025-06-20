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
                viewModel.selectedFoodItem
            },
            set: { newValue in
                // The setter correctly updates the underlying source of truth.
                // When the cover is dismissed, SwiftUI sets this binding's value to nil.
                viewModel.selectedFoodItem = newValue
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
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 5)
                                .onEnded { _ in
                                    print("Backdoor: Long press detected. Initiating archive.")
                                    viewModel.initiateArchiving()
                                }
                        )
                        
                        if showFeedbackInput {
                            FeedbackView(feedbackText: $feedbackText) {
                                viewModel.submitFeedback(feedbackText)
                                withAnimation {
                                    showFeedbackInput = false
                                    feedbackText = ""
                                }
                            }
                            .gesture(
                                DragGesture()
                                    .onEnded { value in
                                        let swipeUp = value.translation.height < -50
                                        let swipeRight = value.translation.width > 50
                                        // If user swipes up or right, close the feedback box
                                        if swipeUp || swipeRight {
                                            withAnimation {
                                                showFeedbackInput = false
                                            }
                                        }
                                    }
                            )
                        }
                        
                        Spacer()
                        
                        if !showFeedbackInput {
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
                                
                                // If the view appears and there are no items, ensure the scene is visually cleared.
                                if viewModel.foodItems.isEmpty {
                                    viewModel.clearJarView()
                                }
                            }
                            .onChange(of: geo.size) { newSize in
                                self.jarViewSize = newSize
                            }
                    }
                    .onTapGesture {
                        if showFeedbackInput {
                            withAnimation {
                                showFeedbackInput = false
                            }
                        }
                    }
                }
                .onChange(of: showFeedbackInput) { isShowing in
                    if !isShowing {
                        // Resign first responder to dismiss the keyboard
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .onChange(of: viewModel.triggerSnapshot) { shouldSnapshot in
                    if shouldSnapshot {
                        let snapshotView = JarContainerView(jarScene: viewModel.jarScene, size: jarViewSize)
                            .frame(width: jarViewSize.width, height: jarViewSize.height)
                            .offset(y: -40)
                        
                        if let image = snapshotView.snapshot()?.croppedToOpaque() {
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
                            Image("cameraIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .padding(10)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .shadow(radius: 5)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }

                // This overlay will appear on top of the whole view when saving.
                /*
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
                */
                
                if viewModel.showArchiveInProgress {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .overlay {
                            VStack {
                                ProgressView()
                                Text("( ˘▽˘)っ Your jar is full! Jas'ing it up...")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }
                }
            }
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationViewStyle(.stack)
        // MARK: - Sheet Modifiers
        .sheet(isPresented: $showImageProcessingSheet, onDismiss: {
            // After the entire sticker creation flow is dismissed, commit the new sticker.
            print("[HomeView] Sheet dismissed. Committing sticker if necessary.")
            viewModel.commitNewStickerIfNecessary()
        }) {
            ImageProcessingView()
                .environmentObject(viewModel)
        }
        // A single, unified full-screen cover for presenting the detail view.
        .fullScreenCover(item: itemForCover, onDismiss: {
            // After the cover is dismissed, ask the view model to commit the new
            // sticker if one exists. This handles the drop-in-jar animation.
            viewModel.commitNewStickerIfNecessary()
            viewModel.resetTemporaryState()
        }) { _ in
            // Pass the single source-of-truth binding to the detail view.
            FoodDetailView(foodItem: $viewModel.selectedFoodItem)
        }
        // A single, unified full-screen cover for presenting the report.
        .fullScreenCover(isPresented: .constant(viewModel.newlyGeneratedReport != nil)) {
            if let report = viewModel.newlyGeneratedReport {
                ReportParchmentView(reportText: report) {
                    // First, dismiss the report view.
                    viewModel.newlyGeneratedReport = nil
                    // Then, trigger the final animation sequence, clearing the stickers.
                    viewModel.finalizeArchiving(clearLocalStickers: true)
                }
            }
        }
        // An alert to show if the saving process fails.
        .alert("Failed to Save Sticker", isPresented: .constant(viewModel.stickerCreationError != nil)) {
            Button("OK") { viewModel.stickerCreationError = nil }
        } message: {
            Text(viewModel.stickerCreationError ?? "An unknown error occurred. Please check your internet connection and try again.")
        }
        // An alert to show if the archiving process fails.
        .alert("Failed to Archive Jar", isPresented: .constant(viewModel.jarArchivingError != nil)) {
            Button("OK") { viewModel.jarArchivingError = nil }
        } message: {
            Text(viewModel.jarArchivingError ?? "An unknown error occurred. Please try again.")
        }
    }
}
