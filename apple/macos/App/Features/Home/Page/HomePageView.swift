import SwiftUI

/// Home feature page. Placeholder-only landing hub.
/// Does not load live project, board, task, or dashboard data — Phase 5 constraint.
struct HomePageView: View {
    var body: some View {
        ContentUnavailableView(
            "Home",
            systemImage: "house",
            description: Text("Dashboard and project entry points — coming soon.")
        )
    }
}

#Preview {
    HomePageView()
}
