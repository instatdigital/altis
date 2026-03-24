import SwiftUI

/// Root application shell. Composes top-level navigation and feature entry points.
///
/// Phase 5: Wires the Home feature flow into the macOS sidebar navigation.
/// The detail area shows `HomePageView` which is placeholder-only — no live
/// project, board, or dashboard data is loaded until later phases.
///
/// Navigation items for Project, Board, TaskList, KanbanBoard, and TaskPage are
/// structural stubs only; they are wired to real feature flows in Phases 6–13.
struct AppShell: View {

    @StateObject private var homeFlow = HomeFeatureFlow()
    @State private var selection: AppRoute? = .home

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                Label("Home", systemImage: "house")
                    .tag(AppRoute.home)
                Label("Projects", systemImage: "folder")
                    .tag(AppRoute.project)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
            .navigationTitle("Altis")
        } detail: {
            detailView(for: selection)
        }
        .onAppear {
            homeFlow.send(.appeared)
        }
    }

    @ViewBuilder
    private func detailView(for route: AppRoute?) -> some View {
        switch route {
        case .home, .none:
            HomePageView()
        case .project:
            ProjectPageView()
        default:
            ContentUnavailableView(
                "Not Available",
                systemImage: "exclamationmark.circle",
                description: Text("This section is available in a later phase.")
            )
        }
    }
}

#Preview {
    AppShell()
}
