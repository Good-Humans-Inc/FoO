import SwiftUI

struct LaunchLoadingView: View {
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // The signature warm background color of the app.
            Color(red: 253/255, green: 249/255, blue: 240/255)
                .ignoresSafeArea()
            
            Image("LogoIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .opacity(isPulsing ? 1.0 : 0.8)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        isPulsing = true
                    }
                }
        }
    }
}

struct LaunchLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LaunchLoadingView()
    }
} 