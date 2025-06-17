import SwiftUI

struct FeedbackView: View {
    // State to hold the text entered by the user.
    @State private var feedbackMessage: String = ""
    
    // An instance of our feedback service to send the message.
    private let feedbackService = FeedbackService()
    
    // A focus state to programmatically dismiss the keyboard.
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        HStack(spacing: 12) {
            // A text field styled to look like a modern chat input.
            TextField("Type a message...", text: $feedbackMessage)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
                .clipShape(Capsule())
                .focused($isTextFieldFocused)

            // The send button's color and disabled state changes based on input.
            Button(action: {
                handleSubmit()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(feedbackMessage.isEmpty ? .gray : Color(red: 236/255, green: 138/255, blue: 83/255))
            }
            .disabled(feedbackMessage.isEmpty)
        }
        .padding(8)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: feedbackMessage.isEmpty)
    }

    /// Handles the submission of the feedback.
    private func handleSubmit() {
        guard !feedbackMessage.isEmpty else { return }
        feedbackService.submitFeedback(message: feedbackMessage)
        
        // Clear the text field and dismiss the keyboard.
        feedbackMessage = ""
        isTextFieldFocused = false
    }
}

#Preview {
    // A more realistic preview showing the view at the bottom.
    ZStack {
        LinearGradient(
            colors: [.gray.opacity(0.3), .gray.opacity(0.1)],
            startPoint: .top,
            endPoint: .bottom
        )
        
        VStack {
            Spacer()
            FeedbackView()
                .padding()
        }
    }
    .ignoresSafeArea()
} 