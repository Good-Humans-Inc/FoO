let creationDate = Date()

// Determine if this item will be special based on the configured probability.
let isSpecial = Double.random(in: 0...1) < specialItemProbability
print("[FirestoreService] New sticker check. Is special: \(isSpecial)")

// Prepare image data for sticker and thumbnail.
guard let stickerImageData = stickerImage.pngData() else {
// ... existing code ...
} 