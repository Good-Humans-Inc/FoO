import SwiftUI

struct FeedbackEntryView: View {
    @Binding var feedbackText: String
    var onSubmit: () -> Void
    var onCancel: () -> Void
    
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationView {
            VStack {
                TextEditor(text: $feedbackText)
                    .padding(5)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                    .focused($isFocused)
                    .onAppear {
                        // By focusing the text editor immediately, we allow SwiftUI to
                        // coordinate the keyboard and sheet animations together.
                        isFocused = true
                    }

                Spacer()
            }
            .padding()
            .background(Color.themeBackground.ignoresSafeArea())
            .navigationTitle("Tell us anything!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel", action: onCancel)
                        .tint(.secondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send", action: onSubmit)
                        .tint(.themeAccent)
                        .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

struct FeedbackEntryView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackEntryView(
            feedbackText: .constant("This is some feedback."),
            onSubmit: {},
            onCancel: {}
        )
    }
} 