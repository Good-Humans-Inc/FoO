import SwiftUI

struct ReportParchmentView: View {
    let reportText: String
    let onDismiss: () -> Void
    
    // State for the animation
    @State private var isRolledUp = true
    
    var body: some View {
        ZStack {
            // A semi-transparent background to dim the view behind it.
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture(perform: dismissWithAnimation)
            
            VStack {
                ScrollView {
                    Text(try! AttributedString(markdown: reportText, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        .padding(40)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(isRolledUp) // Disable scrolling while it's rolled up
                .background(
                    Image("parchment") // Make sure you have a 'parchment.png' asset
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                )
                .cornerRadius(15)
                .shadow(radius: 10)
                // The core of the "unrolling" animation
                .rotation3DEffect(
                    .degrees(isRolledUp ? -90 : 0),
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    anchor: .top
                )
                .offset(y: isRolledUp ? -UIScreen.main.bounds.height / 2 : 0)
            }
            .padding()
            
        }
        .onAppear(perform: unrollWithAnimation)
    }
    
    private func unrollWithAnimation() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            isRolledUp = false
        }
    }
    
    private func dismissWithAnimation() {
        withAnimation(.easeOut(duration: 0.3)) {
            isRolledUp = true
        }
        // Wait for the animation to complete before calling dismiss.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onDismiss()
        }
    }
} 