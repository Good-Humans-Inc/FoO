import SwiftUI

struct JarDetailView: View {
    @StateObject private var viewModel = JarDetailViewModel()
    
    let jar: JarItem
    let userID: String
    
    var body: some View {
        ZStack {
            Color(red: 253/255, green: 249/255, blue: 240/255)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading Jar...")
            } else if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            } else {
                GeometryReader { geo in
                    JarContainerView(jarScene: viewModel.jarScene, size: geo.size)
                        .onAppear {
                            let spriteViewWidth = geo.size.width * 0.78
                            let spriteViewHeight = (geo.size.width * 1.8) * 0.72
                            viewModel.setupScene(with: CGSize(width: spriteViewWidth, height: spriteViewHeight))
                        }
                }
                .offset(y: -40)
            }
        }
        .onAppear {
            viewModel.fetchStickers(for: jar, in: userID)
        }
        .navigationTitle(jar.timestamp.dateValue().formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
    }
} 