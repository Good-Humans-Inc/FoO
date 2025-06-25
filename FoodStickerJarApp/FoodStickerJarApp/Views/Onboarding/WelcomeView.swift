import SwiftUI

struct WelcomeView: View {
    /// The action to perform when the continue button is tapped.
    var onContinue: () -> Void
    
    // State to control the animations.
    @State private var titleIsVisible = false
    @State private var logoIsVisible = false
    @State private var buttonIsVisible = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Welcome to")
                .font(.system(size: 34, weight: .light, design: .serif))
                .foregroundColor(.textPrimary)
                .opacity(titleIsVisible ? 1 : 0)
                .offset(y: titleIsVisible ? 0 : 20)
            
            Text("Jas")
                .font(.system(size: 60, weight: .bold, design: .serif))
                .foregroundColor(.themeAccent)
                .scaleEffect(logoIsVisible ? 1.0 : 0.8)
                .opacity(logoIsVisible ? 1.0 : 0.0)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Let's Go!")
                    .font(.headline)
                    .foregroundColor(.textOnAccent)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themeAccent)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .padding(.horizontal, 40)
            .opacity(buttonIsVisible ? 1 : 0)
        }
        .padding(.bottom, 50)
        .onAppear {
            // Trigger the animations with delays.
            withAnimation(.easeIn(duration: 0.5)) {
                titleIsVisible = true
            }
            
            // The "pop" animation for the logo. A spring animation gives it a nice bounce.
            withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0).delay(0.2)) {
                logoIsVisible = true
            }
            
            withAnimation(.easeIn(duration: 0.5).delay(0.6)) {
                buttonIsVisible = true
            }
        }
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(onContinue: {})
    }
} 