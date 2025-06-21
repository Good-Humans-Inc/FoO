import SwiftUI

struct HomeView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppStateManager

    // State for managing modals and sheets
    @State private var showImageProcessingSheet = false
    @State private var showPaywallCover = false
    
    // UI State
    @State private var showFeedbackInput = false
    @State private var feedbackText = ""
    @State private var jarViewSize: CGSize = .zero

    var body: some View {
        NavigationView {
            ZStack {
                Color.themeBackground.ignoresSafeArea()
                
                // Main content VStack
                VStack(spacing: 0) {
                    // Top bar UI
                    HStack(spacing: 12) {
                        Button(action: {
                            withAnimation {
                                showFeedbackInput.toggle()
                            }
                        }) {
                            Image("logoIcon")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 84, height: 84)
                                .clipShape(Circle())
                        }
                        .simultaneousGesture(
                            LongPressGesture(minimumDuration: 5)
                                .onEnded { _ in
                                    viewModel.initiateArchiving()
                                }
                        )
                        
                        if showFeedbackInput {
                            // Feedback input UI
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
                                        .foregroundColor(feedbackText.isEmpty ? .gray : .themeAccent)
                                }
                                .disabled(feedbackText.isEmpty)
                            }
                            .padding(8)
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 30, style: .continuous)
                            )
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .transition(.opacity.combined(with: .move(edge: .trailing)))
                        }
                        
                        Spacer()
                        
                        if !showFeedbackInput {
                            NavigationLink(destination: ShelfView()) {
                                Image("shelfIcon")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 84, height: 84)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 5)
                    .frame(height: 90)
                    
                    // Jar view
                    GeometryReader { geo in
                        JarContainerView(jarScene: viewModel.jarScene, size: geo.size)
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
                                Text("( ˘▽˘)っ Jas'ing it up...").font(.title2).foregroundColor(.white)
                            }
                        }
                }
            }
            .navigationBarHidden(true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    }
}
