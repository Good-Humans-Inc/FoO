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
                                .onAppear {
                                    // Assign the view to the view model for snapshotting
                                    viewModel.jarViewForSnapshotting = JarContainerView(jarScene: viewModel.jarScene, size: geo.size)
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
                .onDisappear {
                    print("[HomeView] ImageProcessingView sheet disappearing. Attempting to commit sticker.")
                    viewModel.commitNewStickerIfNecessary()
                }
        }
        .fullScreenCover(isPresented: $showPaywallCover) {
            PaywallView(isPresented: $showPaywallCover)
        }
        .fullScreenCover(item: $viewModel.newlyGeneratedReportWrapper) { wrapper in
            ReportParchmentView(reportText: wrapper.report) {
                viewModel.newlyGeneratedReportWrapper = nil
                viewModel.finalizeArchiving(clearLocalStickers: true)
            }
        }
        .alert(item: $viewModel.errorAlert) { errorAlert in
            Alert(
                title: Text(errorAlert.title),
                message: Text(errorAlert.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}
