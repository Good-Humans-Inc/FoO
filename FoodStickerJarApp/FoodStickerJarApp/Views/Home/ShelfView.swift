import SwiftUI
import Kingfisher

struct ShelfView: View {
    @StateObject private var viewModel = ShelfViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // State to control the feedback UI
    @State private var showFeedbackInput = false
    
    // State for the feedback UI is now managed in AppHeaderView
    
    // We no longer need a fixed total number of slots.
    
    // Prepares the jars for display by chunking them into rows of 3.
    // The last row will be padded with `nil` to ensure the layout is always full.
    private var jarRows: [[JarItem?]] {
        let jars = viewModel.jars.map { $0 as JarItem? }
        let chunkedJars = jars.chunked(into: 3)
        
        // If the last row is not full, pad it with nil values.
        guard var lastRow = chunkedJars.last else { return chunkedJars }
        
        let paddingNeeded = 3 - lastRow.count
        if paddingNeeded > 0 {
            lastRow.append(contentsOf: repeatElement(nil, count: paddingNeeded))
        }
        
        var finalRows = Array(chunkedJars.dropLast())
        finalRows.append(lastRow)
        
        return finalRows
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // MARK: - Custom Header
                AppHeaderView(
                    showFeedbackInput: $showFeedbackInput,
                    submitFeedback: viewModel.submitFeedback
                ) {
                    Button(action: { dismiss() }) {
                        Image("exit")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 56)
                    }
                }

                // This VStack groups the content below the header, allowing a single tap gesture.
                VStack {
                    Spacer()

                    // MARK: - Jars on Shelves
                    if viewModel.isLoading {
                        ProgressView("Loading Shelf...")
                            .frame(maxHeight: .infinity)
                    } else if viewModel.jars.isEmpty {
                        // Special view for when there are no jars yet.
                        VStack {
                            Spacer()
                            Text("(°ー°〃) Your shelf is empty.")
                                .font(.title2)
                                .foregroundColor(.secondary)
                            Text("A jar will show up here when it's archived!")
                                .font(.body)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    } else {
                        ScrollView {
                            VStack(spacing: 20) {
                                ForEach(0..<jarRows.count, id: \.self) { rowIndex in
                                    let row = jarRows[rowIndex]
                                    ShelfRowView(row: row, userID: viewModel.userID)
                                }
                            }
                            .padding(.top) // Add some space from the header
                        }
                    }
                    Spacer()
                }
                .onTapGesture {
                    if showFeedbackInput {
                        withAnimation {
                            showFeedbackInput = false
                        }
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

// MARK: - Subviews

/// A view for a single shelf with up to 3 jars.
private struct ShelfRowView: View {
    let row: [JarItem?]
    let userID: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            Image("bar") // Use the correct 'bar' asset for the shelf
                .resizable()
                .scaledToFit()
            
            HStack(spacing: 20) {
                // Populate left-to-right
                ForEach(0..<row.count, id: \.self) { index in
                    let jar = row[index]
                    
                    if let jar = jar, let url = URL(string: jar.screenshotThumbnailURL) {
                        NavigationLink(destination: JarDetailView(jar: jar)) {
                            KFImage(url)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    } else {
                        // Empty jar placeholder
                        Image("glassJar")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .opacity(0.3) // Make it look empty/inactive
                    }
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 25) // Fine-tune this to place jars on the shelf
        }
        .frame(maxWidth: .infinity)
    }
}

struct ShelfView_Previews: PreviewProvider {
    static var previews: some View {
        ShelfView()
    }
} 
