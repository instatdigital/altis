import SwiftUI

/// Root application shell. Composes top-level navigation and feature entry points.
///
/// Owns the `AppEnvironment` (SQLite store + workspace identity) and creates
/// all top-level feature flows with their concrete data workers.
///
/// Phase 5: Home feature flow wired into macOS `NavigationSplitView`.
/// Phase 6: Project feature flow wired; real `ProjectPageView` with list and
///          create-project sheet replaces the placeholder.
///
/// Navigation items for Board, TaskList, KanbanBoard, and TaskPage remain
/// structural stubs wired to real flows in Phases 7–13.
struct AppShell: View {

    @StateObject private var homeFlow: HomeFeatureFlow
    @StateObject private var projectFlow: ProjectFeatureFlow

    @State private var selection: AppRoute? = .home

    init(environment: AppEnvironment) {
        _homeFlow = StateObject(wrappedValue: HomeFeatureFlow())
        _projectFlow = StateObject(wrappedValue: ProjectFeatureFlow(
            worker: OfflineProjectDataWorker(
                store: environment.store,
                workspaceId: environment.workspaceId
            ),
            workspaceId: environment.workspaceId
        ))
    }

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
            ProjectPageView(flow: projectFlow)
        default:
            ContentUnavailableView(
                "Not Available",
                systemImage: "exclamationmark.circle",
                description: Text("This section is available in a later phase.")
            )
        }
    }
}
