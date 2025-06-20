import SwiftUI

struct FeedbackView: View {
    @Binding var feedbackText: String
    var onSubmit: () -> Void

    // --- Contact Info ---
    // You can replace these with your actual links and email address.
    private let instagramURL = URL(string: "https://www.instagram.com/xielr_l")!
    private let tiktokURL = URL(string: "https://www.tiktok.com/@your_username_here")!
    private let emailAddress = "contact@goodhumans.today"
    
    // State to provide feedback when email is copied
    @State private var didCopyEmail = false

    var body: some View {
        VStack(spacing: 12) {
            // Main input section
            HStack(spacing: 12) {
                TextField("Tell us anything!", text: $feedbackText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.5))
                    .clipShape(Capsule())

                Button(action: onSubmit) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(feedbackText.isEmpty ? .gray.opacity(0.5) : .themeAccent)
                }
                .disabled(feedbackText.isEmpty)
            }
            
            Group {
                if didCopyEmail {
                    Text("Copied email address (ﾉ^▽^)ﾉ")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .transition(.opacity)
                } else {
                    // Social media and contact links
                    HStack(spacing: 25) {
                        Link(destination: instagramURL) {
                            Image("instagramLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                        
                        Link(destination: tiktokURL) {
                            Image("tiktokLogo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)
                        }
                            
                        Button(action: copyEmail) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.secondary)
                        }
                    }
                    .transition(.opacity)
                }
            }
            .padding(.top, 5)
        }
        .padding()
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: feedbackText.isEmpty)
        .animation(.easeIn(duration: 0.2), value: didCopyEmail)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
    
    private func copyEmail() {
        // Copy the email address to the system pasteboard.
        UIPasteboard.general.string = emailAddress
        
        // Trigger the visual feedback.
        withAnimation {
            didCopyEmail = true
        }
        
        // Reset the feedback after 2 seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                didCopyEmail = false
            }
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            FeedbackView(feedbackText: .constant(""), onSubmit: {})
        }
    }
} 