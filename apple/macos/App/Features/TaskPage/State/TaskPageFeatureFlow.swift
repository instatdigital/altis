import Foundation
import _Concurrency

/// Feature flow for the Task Detail page.
///
/// Owns `TaskPageFeatureState` and processes `TaskPageFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded and mutations persisted via `OfflineTaskPageDataWorker`.
/// - `online` boards: data loaded via an online gateway — routing point defined here,
///   gateway attached in Phase 14.
@MainActor
final class TaskPageFeatureFlow: ObservableObject {

    @Published private(set) var state = TaskPageFeatureState()

    private let offlineWorker: OfflineTaskPageDataWorker

    init(offlineWorker: OfflineTaskPageDataWorker) {
        self.offlineWorker = offlineWorker
    }

    // MARK: - Event entry point

    func send(_ event: TaskPageFeatureEvent) {
        switch event {
        case .appeared(let taskId, let boardMode):
            state.boardMode = boardMode
            loadTask(taskId: taskId, boardMode: boardMode)

        case .stageMoveRequested, .completeRequested, .failRequested:
            // Phase 9 / Phase 13 implementation.
            break

        case .offlineTaskLoaded(let projection):
            state.task = projection
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

    private func loadTask(taskId: TaskID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            _Concurrency.Task {
                do {
                    let projection = try await offlineWorker.loadTask(taskId: taskId)
                    send(.offlineTaskLoaded(projection))
                } catch {
                    send(.loadFailed(error))
                }
            }
        case .online:
            send(.onlineUnavailable(.notImplemented))
        }
    }
}
