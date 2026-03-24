import Foundation
import _Concurrency

/// Feature flow for the Task List presentation.
///
/// Owns `TaskListFeatureState` and processes `TaskListFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded via `OfflineTaskListDataWorker` (local SQLite).
/// - `online` boards: data loaded via an online gateway — routing point defined here,
///   gateway attached in Phase 14.
@MainActor
final class TaskListFeatureFlow: ObservableObject {

    @Published private(set) var state = TaskListFeatureState()

    private let offlineWorker: OfflineTaskListDataWorker

    init(offlineWorker: OfflineTaskListDataWorker) {
        self.offlineWorker = offlineWorker
    }

    // MARK: - Event entry point

    func send(_ event: TaskListFeatureEvent) {
        switch event {
        case .appeared(let boardId, let boardMode):
            state.boardId = boardId
            state.boardMode = boardMode
            loadTasks(boardId: boardId, boardMode: boardMode)

        case .taskSelected:
            // Navigation handled by the page/shell layer.
            break

        case .offlineTasksLoaded(let tasks):
            state.tasks = tasks
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.isLoading = false
            state.onlineUnavailable = reason

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Effects

    private func loadTasks(boardId: BoardID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            _Concurrency.Task {
                do {
                    let tasks = try await offlineWorker.loadTasks(boardId: boardId)
                    send(.offlineTasksLoaded(tasks))
                } catch {
                    send(.loadFailed(error))
                }
            }
        case .online:
            send(.onlineUnavailable(.notImplemented))
        }
    }
}
