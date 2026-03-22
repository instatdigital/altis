import SwiftUI

/// Root application shell. Composes top-level navigation and feature entry points.
/// Placeholder — structural shell only; feature content wired in later phases.
struct AppShell: View {
    var body: some View {
        NavigationSplitView {
            List {
                Label("Home", systemImage: "house")
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            Text("Altis")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

#Preview {
    AppShell()
}
