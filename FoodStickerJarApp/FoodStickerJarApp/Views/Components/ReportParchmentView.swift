import SwiftUI

struct ReportParchmentView: View {
    let reportText: String
    let confirmAction: () -> Void

    var body: some View {
        ZStack {
            // Use a material background for the "frosted glass" effect.
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 30) {
                ScrollView {
                    // Use AttributedString to render the markdown.
                    Text(try! AttributedString(markdown: reportText, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                        .font(.custom("AvenirNext-Medium", size: 18))
                        .foregroundColor(.primary) // Adapts to light/dark mode
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 50)
                }

                Button(action: confirmAction) {
                    Text("Got it!")
                        .font(.custom("AvenirNext-Bold", size: 20))
                        .foregroundColor(.primary)
                        .padding(.vertical, 15)
                        .padding(.horizontal, 40)
                        .background(.regularMaterial) // Match the glass style
                        .cornerRadius(25)
                }
                .padding(.bottom, 40)
            }
        }
    }
} 