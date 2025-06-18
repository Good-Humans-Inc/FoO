import SwiftUI
import Kingfisher

struct ShelfView: View {
    @StateObject private var viewModel = ShelfViewModel()
    
    let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color(red: 253/255, green: 249/255, blue: 240/255)
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView("Loading Shelf...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack {
                    Text("Failed to load shelf")
                        .font(.headline)
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if viewModel.jars.isEmpty {
                Text("Your shelf is empty. Archive your first jar!")
                    .font(.title2)
                    .foregroundColor(.secondary)
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(viewModel.jars) { jar in
                            NavigationLink(destination: JarDetailView(jar: jar, userID: viewModel.userID ?? "")) {
                                if let url = URL(string: jar.screenshotThumbnailURL) {
                                    KFImage(url)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .cornerRadius(15)
                                        .shadow(radius: 5)
                                }
                            }
                            .disabled(viewModel.userID == nil)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("My Shelf")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShelfView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ShelfView()
        }
    }
} 