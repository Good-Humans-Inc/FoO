import SwiftUI
import Kingfisher

struct ShelfView: View {
    @StateObject private var viewModel = ShelfViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // State for the feedback UI
    @State private var showFeedbackInput = false
    @State private var feedbackText = ""
    
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
                        .frame(maxHeight: .infinity)
                } else if viewModel.jars.isEmpty {
                    // Special view for when there are no jars yet.
                    VStack {
                        Spacer()
                        Text("Your shelf is empty.")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Archive a jar to see it here!")
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
