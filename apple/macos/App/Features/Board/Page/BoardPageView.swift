import SwiftUI

/// Board feature page. Placeholder — implemented in Phase 7.
struct BoardPageView: View {
    var body: some View {
        ContentUnavailableView(
            "Boards",
            systemImage: "square.grid.3x1.below.line.grid.1x2",
            description: Text("Board list and creation — coming soon.")
        )
    }
}

#Preview {
    BoardPageView()
}
