import SwiftUI

/// Root application shell. Composes top-level navigation and feature entry points.
///
/// Owns the `AppEnvironment` (SQLite store + workspace identity) and creates
/// all top-level feature flows with their concrete data workers.
///
/// Phase 5: Home feature flow wired into macOS `NavigationSplitView`.
/// Phase 6: Project feature flow wired; real `ProjectPageView` with list and
///          create-project sheet replaces the placeholder.
/// Phase 7: Board feature flow wired; `BoardPageView` replaces the stub.
/// Phase 9: Task page flow wired; `TaskPageView` replaces the stub.
///          Board rows navigate to a task list (Phase 10 renders tasks;
///          Phase 9 provides the create-task entry point).
/// Phase 10: Task list flow wired; `TaskListPageView` renders tasks from
///           offline local typed projections.
struct AppShell: View {

    @StateObject private var homeFlow: HomeFeatureFlow
    @StateObject private var projectFlow: ProjectFeatureFlow
    @StateObject private var boardFlow: BoardFeatureFlow
    @StateObject private var taskPageFlow: TaskPageFeatureFlow
    @StateObject private var taskListFlow: TaskListFeatureFlow

    private let environment: AppEnvironment

    @State private var selection: AppRoute? = .home

    init(environment: AppEnvironment) {
        self.environment = environment
        _homeFlow = StateObject(wrappedValue: HomeFeatureFlow())
        _projectFlow = StateObject(wrappedValue: ProjectFeatureFlow(
            worker: OfflineProjectDataWorker(
                store: environment.store,
                workspaceId: environment.workspaceId
            ),
            workspaceId: environment.workspaceId
        ))
        _boardFlow = StateObject(wrappedValue: BoardFeatureFlow(
            offlineWorker: OfflineLocalBoardWorker(store: environment.store),
            onlineGateway: NotImplementedOnlineBoardGateway(),
            store: environment.store,
            workspaceId: environment.workspaceId
        ))
        _taskPageFlow = StateObject(wrappedValue: TaskPageFeatureFlow(
            offlineWorker: OfflineTaskPageWorker(store: environment.store),
            store: environment.store as any LocalStoreContract & LocalWritePathContract
        ))
        _taskListFlow = StateObject(wrappedValue: TaskListFeatureFlow(
            offlineWorker: OfflineTaskListWorker(store: environment.store)
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
            ProjectPageView(flow: projectFlow, onProjectSelected: { projectId in
                selection = .boardList(projectId: projectId, workspaceId: environment.workspaceId)
            })
        case .boardList(let projectId, let workspaceId):
            BoardPageView(
                flow: boardFlow,
                projectId: projectId,
                workspaceId: workspaceId,
                onBoardSelected: { boardId, boardMode in
                    selection = .taskList(boardId: boardId, boardMode: boardMode)
                }
            )
        case .taskList(let boardId, let boardMode):
            TaskListPageView(
                taskListFlow: taskListFlow,
                taskPageFlow: taskPageFlow,
                boardId: boardId,
                boardMode: boardMode,
                workspaceId: environment.workspaceId,
                onTaskSelected: { taskId in
                    selection = .taskPage(taskId: taskId, boardMode: boardMode)
                }
            )
        case .taskPage(let taskId, let boardMode):
            TaskPageView(flow: taskPageFlow)
                .onAppear {
                    taskPageFlow.send(.appeared(taskId: taskId, boardMode: boardMode))
                }
        default:
            ContentUnavailableView(
                "Not Available",
                systemImage: "exclamationmark.circle",
                description: Text("This section is available in a later phase.")
            )
        }
    }
}
