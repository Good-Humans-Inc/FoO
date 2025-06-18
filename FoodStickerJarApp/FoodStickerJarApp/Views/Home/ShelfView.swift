import SwiftUI
import Kingfisher

struct ShelfView: View {
    @StateObject private var viewModel = ShelfViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // State for the feedback UI
    @State private var showFeedbackInput = false
    @State private var feedbackText = ""
    
    // Total number of slots for jars (3 shelves * 3 jars per shelf)
    private let totalSlots = 9
    
    // Prepares the jars for display. We need to create a full grid of 9,
    // with empty placeholders for jars that don't exist yet.
    private var jarGrid: [JarItem?] {
        let jars = viewModel.jars
        var grid = [JarItem?](repeating: nil, count: totalSlots)
        
        let numCols = 3
        let numRows = 3

        // Populate the grid from the bottom-left up.
        for (index, jar) in jars.enumerated() {
            if index < totalSlots {
                // Formula to map a linear index to a grid filled from bottom-to-top.
                let row = numRows - 1 - (index / numCols)
                let col = index % numCols
                let gridIndex = row * numCols + col
                
                if gridIndex >= 0 && gridIndex < totalSlots {
                    grid[gridIndex] = jar
                }
            }
        }
        return grid
    }
    
    // Chunk the 1D grid into a 2D array of rows for the UI.
    private var jarRows: [[JarItem?]] {
        jarGrid.chunked(into: 3)
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // MARK: - Custom Header
                HStack(alignment: .center, spacing: 12) {
                    // Logo and feedback button
                    Button(action: {
                        withAnimation {
                            showFeedbackInput.toggle()
                        }
                    }) {
                        Image("logoIcon") // Make sure this asset exists
                            .resizable()
                            .scaledToFit()
                            .frame(height: 84)
                    }
                    
                    if showFeedbackInput {
                        FeedbackInputView(feedbackText: $feedbackText) {
                            viewModel.submitFeedback(feedbackText)
                            withAnimation {
                                showFeedbackInput = false
                                feedbackText = ""
                            }
                        }
                    } else {
                        Spacer()
                        // Exit Button
                        Button(action: { dismiss() }) {
                            Image("exit") // Use the custom exit icon
                                .resizable()
                                .scaledToFit()
                                .frame(height: 84)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top)

                Spacer()

                // MARK: - Jars on Shelves
                if viewModel.isLoading {
                    ProgressView("Loading Shelf...")
                } else {
                    // Always render 3 shelves.
                    // The rows are ordered top to bottom.
                    ForEach(0..<jarRows.count, id: \.self) { rowIndex in
                        let row = jarRows[rowIndex]
                        ShelfRowView(row: row, userID: viewModel.userID)
                    }
                }
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Subviews

/// A view for the feedback text field and submission button.
private struct FeedbackInputView: View {
    @Binding var feedbackText: String
    var onSubmit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            TextField("Confused? Tell me about it...", text: $feedbackText)
                .textFieldStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.thinMaterial)
                .clipShape(Capsule())

            Button(action: onSubmit) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(feedbackText.isEmpty ? .gray : Color(red: 236/255, green: 138/255, blue: 83/255))
            }
            .disabled(feedbackText.isEmpty)
        }
        .padding(8)
        .background(
            .ultraThinMaterial,
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: feedbackText.isEmpty)
        .transition(.opacity.combined(with: .move(edge: .trailing)))
    }
}


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
