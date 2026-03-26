import Foundation
import _Concurrency

/// Feature flow for the Task List presentation.
///
/// Owns `TaskListFeatureState` and processes `TaskListFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded via `OfflineTaskListDataWorker` (local SQLite).
/// - `online` boards: access gated by `OnlineBoardAuthGateContract`, then loaded
///   from `OnlineBoardGatewayContract`.
@MainActor
final class TaskListFeatureFlow: ObservableObject {

    @Published private(set) var state = TaskListFeatureState()

    private let offlineWorker: OfflineTaskListDataWorker
    private let onlineAuthGate: OnlineBoardAuthGateContract
    private let onlineGateway: OnlineBoardGatewayContract
    private var activeTasks: [_Concurrency.Task<Void, Never>] = []

    init(
        offlineWorker: OfflineTaskListDataWorker,
        onlineAuthGate: OnlineBoardAuthGateContract,
        onlineGateway: OnlineBoardGatewayContract
    ) {
        self.offlineWorker = offlineWorker
        self.onlineAuthGate = onlineAuthGate
        self.onlineGateway = onlineGateway
    }

    deinit {
        for task in activeTasks { task.cancel() }
    }

    // MARK: - Event entry point

    func send(_ event: TaskListFeatureEvent) {
        switch event {
        case .appeared(let boardId, let boardMode):
            if state.boardId != boardId {
                cancelActiveTasks()
                state.tasks = []
                state.onlineUnavailable = nil
                state.errorMessage = nil
            }
            state.boardId = boardId
            state.boardMode = boardMode
            loadTasks(boardId: boardId, boardMode: boardMode)

        case .taskSelected:
            // Navigation handled by the page/shell layer.
            break

        case .offlineTasksLoaded(let tasks):
            state.onlineUnavailable = nil
            state.errorMessage = nil
            state.tasks = tasks
            state.isLoading = false

        case .onlineTasksLoaded(let tasks):
            state.onlineUnavailable = nil
            state.errorMessage = nil
            state.tasks = tasks
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.tasks = []
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

    private func loadTasks(boardId: BoardID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            spawnTask {
                do {
                    let tasks = try await self.offlineWorker.loadTasks(boardId: boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineTasksLoaded(tasks))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.loadFailed(error))
                }
            }
        case .online:
            spawnTask {
                do {
                    try await self.onlineAuthGate.requireAccess()
                    let content = try await self.onlineGateway.fetchBoardContent(boardId: boardId)
                    let orderedStages = content.stages.sorted(by: { $0.orderIndex < $1.orderIndex })
                    let tasks = content.tasks.map { TaskListItemProjection(onlineTask: $0, stages: orderedStages) }
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.onlineTasksLoaded(tasks))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.onlineUnavailable(OnlineBoardUnavailableReason(error: error)))
                }
            }
        }
    }
}
