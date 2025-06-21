import SwiftUI

/// A reusable header view that standardizes the app's top navigation bar.
/// It includes a logo button that toggles a feedback view, and allows for custom trailing content.
struct AppHeaderView<TrailingContent: View>: View {
    
    // The parent view controls the visibility of the feedback pop-up.
    @Binding var showFeedbackInput: Bool
    
    // The view model must provide a way to submit feedback.
    var submitFeedback: (String) -> Void
    // The custom content for the trailing side of the header (e.g., an exit or shelf button).
    @ViewBuilder let trailingContent: () -> TrailingContent
    
    // State for managing the feedback sheet presentation
    @State private var showFeedbackSheet = false
    @State private var feedbackText = ""

    var body: some View {
        VStack {
            HStack(alignment: .center, spacing: 12) {
                // Logo acts as the button to toggle feedback
                Button(action: {
                    withAnimation {
                        showFeedbackInput.toggle()
                    }
                }) {
                    Image("jasIcon")
                        .resizable()
                        .scaledToFit()
                        .frame(height: 44)
                }
                
                if showFeedbackInput {
                    // The feedback pop-up view
                    FeedbackView(onStartTyping: {
                        showFeedbackSheet = true
                    })
                    .gesture(
                        DragGesture().onEnded { value in
                            let horizontal = value.translation.width
                            let vertical = value.translation.height
                            let swipeThreshold: CGFloat = 50

                            if abs(horizontal) > abs(vertical) {
                                // Right swipe
                                if horizontal > swipeThreshold {
                                    withAnimation {
                                        showFeedbackInput = false
                                    }
                                }
                            } else {
                                // Up swipe
                                if vertical < -swipeThreshold {
                                    withAnimation {
                                        showFeedbackInput = false
                                    }
                                }
                            }
                        }
                    )
                } else {
                    Spacer()
                    // Custom trailing content
                    trailingContent()
                }
            }
            .padding()
        }
        .sheet(isPresented: $showFeedbackSheet) {
            FeedbackEntryView(
                feedbackText: $feedbackText,
                onSubmit: {
                    submitFeedback(feedbackText)
                    feedbackText = ""
                    showFeedbackSheet = false
                    // Also hide the pop-up after submission
                    showFeedbackInput = false
                },
                onCancel: {
                    feedbackText = ""
                    showFeedbackSheet = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .onChange(of: showFeedbackInput) { isShowing in
            if !isShowing {
                // Dismiss the keyboard if the pop-up is closed
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
        }
    }
} 