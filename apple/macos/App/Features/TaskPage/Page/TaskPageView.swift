import SwiftUI

/// Task page feature view. Placeholder — implemented in Phase 9.
struct TaskPageView: View {
    var body: some View {
        ContentUnavailableView(
            "Task",
            systemImage: "doc.text",
            description: Text("Task detail and editing — coming soon.")
        )
    }
}

#Preview {
    TaskPageView()
}
