import SwiftUI

struct JarDetailView: View {
    @StateObject private var viewModel = JarDetailViewModel()
    
    let jar: JarItem
    
    var body: some View {
        ZStack {
            Color(red: 253/255, green: 249/255, blue: 240/255)
                .ignoresSafeArea()
            
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
        .onAppear {
            viewModel.setup(for: jar)
        }
        .navigationTitle(jar.timestamp.dateValue().formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $viewModel.selectedFoodItem) { foodItem in
            let binding = Binding<FoodItem?>(
                get: { viewModel.selectedFoodItem },
                set: { viewModel.selectedFoodItem = $0 }
            )
            FoodDetailView(foodItem: binding)
        }
    }
} 