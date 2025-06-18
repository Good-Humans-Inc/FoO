import SwiftUI

struct ShelfView: View {
    var body: some View {
        Text("This is the Shelf View!")
            .navigationTitle("My Shelf")
    }
}

struct ShelfView_Previews: PreviewProvider {
    static var previews: some View {
        ShelfView()
    }
} 