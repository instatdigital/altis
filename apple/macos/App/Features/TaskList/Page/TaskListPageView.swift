import SwiftUI

/// Task list feature page. Placeholder — implemented in Phase 10.
struct TaskListPageView: View {
    var body: some View {
        ContentUnavailableView(
            "Tasks",
            systemImage: "checklist",
            description: Text("Task list — coming soon.")
        )
    }
}

#Preview {
    TaskListPageView()
}
