import Foundation
import _Concurrency

/// Feature flow for the Kanban Board presentation.
///
/// Owns `KanbanBoardFeatureState` and processes `KanbanBoardFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded and mutations persisted via `OfflineKanbanDataWorker`.
/// - `online` boards: data loaded via an online gateway — routing point defined here,
///   gateway attached in Phase 14.
@MainActor
final class KanbanBoardFeatureFlow: ObservableObject {

    @Published private(set) var state = KanbanBoardFeatureState()

    private let offlineWorker: OfflineKanbanDataWorker
    private var activeTasks: [_Concurrency.Task<Void, Never>] = []

    init(offlineWorker: OfflineKanbanDataWorker) {
        self.offlineWorker = offlineWorker
    }

    deinit {
        for task in activeTasks { task.cancel() }
    }

    // MARK: - Event entry point

    func send(_ event: KanbanBoardFeatureEvent) {
        switch event {
        case .appeared(let boardId, let boardMode):
            if state.boardId != boardId {
                cancelActiveTasks()
                state.columns = []
                state.onlineUnavailable = nil
                state.errorMessage = nil
            }
            state.boardId = boardId
            state.boardMode = boardMode
            loadColumns(boardId: boardId, boardMode: boardMode)

        case .taskSelected:
            // Navigation handled by the page/shell layer.
            break

        case .taskMoved(let taskId, let toStageId):
            guard let boardId = state.boardId else { break }
            moveTask(taskId: taskId, toStageId: toStageId, boardId: boardId, boardMode: state.boardMode)

        case .taskCompleteRequested, .taskFailRequested:
            // Phase 13 implementation.
            break

        case .offlineColumnsLoaded(let columns):
            state.columns = columns
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.isLoading = false
            state.onlineUnavailable = reason

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Task lifecycle

    func cancelActiveTasks() {
        for task in activeTasks { task.cancel() }
        activeTasks.removeAll()
    }

    func cancelAndDrainActiveTasks() async {
        let snapshot = activeTasks
        activeTasks.removeAll()
        for task in snapshot {
            task.cancel()
            _ = await task.result
        }
    }

    @discardableResult
    private func spawnTask(_ body: @escaping () async -> Void) -> _Concurrency.Task<Void, Never> {
        let task = _Concurrency.Task { await body() }
        activeTasks.append(task)
        _Concurrency.Task {
            _ = await task.result
            self.activeTasks.removeAll(where: { $0 == task })
        }
        return task
    }

    // MARK: - Effects

    private func moveTask(taskId: TaskID, toStageId: BoardStageID, boardId: BoardID, boardMode: BoardMode) {
        switch boardMode {
        case .offline:
            spawnTask {
                do {
                    try await self.offlineWorker.moveTask(taskId: taskId, toStageId: toStageId, boardId: boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    // Reload columns so all views reflect the updated projection.
                    let columns = try await self.offlineWorker.loadColumns(boardId: boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineColumnsLoaded(columns))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.loadFailed(error))
                }
            }
        case .online:
            send(.onlineUnavailable(.notImplemented))
        }
    }

    private func loadColumns(boardId: BoardID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            spawnTask {
                do {
                    let columns = try await self.offlineWorker.loadColumns(boardId: boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineColumnsLoaded(columns))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.loadFailed(error))
                }
            }
        case .online:
            send(.onlineUnavailable(.notImplemented))
        }
    }
}
