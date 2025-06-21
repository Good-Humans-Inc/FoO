import SwiftUI

struct JarDetailView: View {
    @StateObject private var viewModel = JarDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // State to control the feedback UI
    @State private var showFeedbackInput = false
    
    // State for the new UI elements is now managed in AppHeaderView
    @State private var showReport = false
    
    let jar: JarItem
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Header
                AppHeaderView(
                    showFeedbackInput: $showFeedbackInput,
                    submitFeedback: viewModel.submitFeedback
                ) {
                    Button(action: { dismiss() }) {
                        Image("exit")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    }
                }

                // MARK: - Jar Content
                GeometryReader { geo in
                    JarContainerView(jarScene: viewModel.jarScene, size: geo.size)
                        .onAppear {
                            let spriteViewWidth = geo.size.width * 0.78
                            let spriteViewHeight = (geo.size.width * 1.8) * 0.72
                            viewModel.setupScene(with: CGSize(width: spriteViewWidth, height: spriteViewHeight))
                        }
                }
                .offset(y: -80)
                .onTapGesture {
                    if showFeedbackInput {
                        withAnimation {
                            showFeedbackInput = false
                        }
                    }
                }

                // MARK: - Report Button
                Button(action: {
                    showReport = true
                }) {
                    Image("reportIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(radius: 5)
                }
                .padding(.bottom)
            }
        }
        .onAppear {
            viewModel.setup(for: jar)
        }
        .navigationBarHidden(true)
        .fullScreenCover(item: $viewModel.selectedFoodItem) { foodItem in
            let binding = Binding<FoodItem?>(
                get: { viewModel.selectedFoodItem },
                set: { viewModel.selectedFoodItem = $0 }
            )
            FoodDetailView(foodItem: binding)
        }
        .fullScreenCover(isPresented: $showReport) {
            ReportParchmentView(reportText: jar.report ?? "No report available.") {
                showReport = false
            }
        }
    }
}

// MARK: - Reusable Subviews

// The private FeedbackInputView is no longer needed. 