import SwiftUI

struct JarDetailView: View {
    @StateObject private var viewModel = JarDetailViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // State for the new UI elements
    @State private var showFeedbackInput = false
    @State private var feedbackText = ""
    @State private var showReport = false
    
    let jar: JarItem
    
    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Header
                HStack(alignment: .center, spacing: 12) {
                    Button(action: {
                        withAnimation {
                            showFeedbackInput.toggle()
                        }
                    }) {
                        Image("logoIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 84)
                    }
                    
                    if showFeedbackInput {
                        FeedbackInputView(feedbackText: $feedbackText) {
                            viewModel.submitFeedback(feedbackText)
                            withAnimation {
                                showFeedbackInput = false
                                feedbackText = ""
                            }
                        }
                    } else {
                        Spacer()
                        Button(action: { dismiss() }) {
                            Image("exit")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 84)
                        }
                    }
                }
                .padding()

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
        .sheet(isPresented: $showReport) {
            ReportView(report: jar.report)
        }
    }
}

// MARK: - Reusable Subviews

private struct ReportView: View {
    let report: String?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                Text(report ?? "No report available for this week.")
                    .padding()
            }
            .navigationTitle("Weekly Report")
            .navigationBarItems(trailing: Button("Done") {
                dismiss()
            })
        }
    }
}

private struct FeedbackInputView: View {
    @Binding var feedbackText: String
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Confused? Tell me about it...", text: $feedbackText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(Capsule())

            Button(action: onSubmit) {
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
    }
} 