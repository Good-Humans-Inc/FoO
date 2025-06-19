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
                .opacity(titleIsVisible ? 1 : 0)
                .offset(y: titleIsVisible ? 0 : 20)
            
            Text("Jas")
                .font(.system(size: 60, weight: .bold, design: .serif))
                .foregroundColor(Color(red: 236/255, green: 138/255, blue: 83/255))
                .scaleEffect(logoIsVisible ? 1 : 0.5)
                .opacity(logoIsVisible ? 1 : 0)
            
            Spacer()
            
            Button(action: onContinue) {
                Text("Let's Go!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(red: 236/255, green: 138/255, blue: 83/255))
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
            
            withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3)) {
                logoIsVisible = true
            }
            
            withAnimation(.easeIn(duration: 0.5).delay(0.8)) {
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