import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppStateManager

    // State for managing modals and sheets
    @State private var showImageProcessingSheet = false
    @State private var showPaywallCover = false
    
    // UI State
    @State private var showFeedbackInput = false
    
    // State for the new UI is now managed in AppHeaderView
    @State private var jarViewSize: CGSize = .zero

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                // Main content VStack
                VStack(spacing: 0) {
                    AppHeaderView(
                        showFeedbackInput: $showFeedbackInput,
                        submitFeedback: viewModel.submitFeedback
                    ) {
                        NavigationLink(destination: ShelfView()) {
                            Image("shelfIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 84, height: 84)
                        }
                        .transition(.opacity)
                    }
                    .frame(height: 90) // Give the top bar a fixed height
                    
                    GeometryReader { geo in
                        ZStack {
                            JarContainerView(jarScene: viewModel.jarScene, size: geo.size)
                                .disabled(showFeedbackInput)

                            // Overlay for dismissing feedback
                            if showFeedbackInput {
                                Color.clear
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation {
                                            showFeedbackInput = false
                                        }
                                    }
                            }
                        }
                        .frame(width: geo.size.width, height: geo.size.height)
                        .offset(y: -40)
                        .onAppear {
                            self.jarViewSize = geo.size
                            let spriteViewSize = CGSize(width: geo.size.width * 0.78, height: geo.size.width * 1.8 * 0.72)
                            viewModel.setupScene(with: spriteViewSize)
                            if viewModel.foodItems.isEmpty {
                                viewModel.clearJarView()
                            }
                        }
                    }
                }
                .onChange(of: viewModel.triggerSnapshot) { shouldSnapshot in
                    if shouldSnapshot {
                        // Snapshot logic
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
                
                // Floating Camera Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: {
                            let stickerCount = viewModel.userProfile?.stickerCount ?? 0
                            if appState.isSubscribed || stickerCount < 5 {
                                showImageProcessingSheet = true
                            } else {
                                showPaywallCover = true
                            }
                        }) {
                            Image("cameraIcon")
                                .resizable().scaledToFit().frame(width: 64, height: 64)
                                .padding(10).background(.ultraThinMaterial)
                                .clipShape(Circle()).shadow(radius: 5)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }

                // Saving Overlay
                if viewModel.showArchiveInProgress {
                    Color.black.opacity(0.5).ignoresSafeArea()
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
        
        // MARK: - Modifiers
        .sheet(isPresented: $showImageProcessingSheet) {
            ImageProcessingView()
                .environmentObject(viewModel)
                .onDisappear(perform: viewModel.commitNewStickerIfNecessary)
        }
        .fullScreenCover(isPresented: $showPaywallCover) {
            PaywallView(isPresented: $showPaywallCover)
        }
        .fullScreenCover(isPresented: .constant(viewModel.newlyGeneratedReport != nil)) {
            if let report = viewModel.newlyGeneratedReport {
                ReportParchmentView(reportText: report) {
                    viewModel.newlyGeneratedReport = nil
                    viewModel.finalizeArchiving(clearLocalStickers: true)
                }
            }
        }
        .alert("Failed to Save Sticker", isPresented: .constant(viewModel.stickerCreationError != nil)) {
            Button("OK") { viewModel.stickerCreationError = nil }
        } message: {
            Text(viewModel.stickerCreationError ?? "An unknown error occurred.")
        }
        // An alert to show if the archiving process fails.
        .alert("Failed to Archive Jar", isPresented: .constant(viewModel.jarArchivingError != nil)) {
            Button("OK") { viewModel.jarArchivingError = nil }
        } message: {
            Text(viewModel.jarArchivingError ?? "An unknown error occurred. Please try again.")
        }
    }
}
