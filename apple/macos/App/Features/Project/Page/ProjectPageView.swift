import SwiftUI

/// Project feature page. Placeholder — implemented in Phase 6.
struct ProjectPageView: View {
    var body: some View {
        ContentUnavailableView(
            "Projects",
            systemImage: "folder",
            description: Text("Project list and creation — coming soon.")
        )
    }
}

#Preview {
    ProjectPageView()
}
