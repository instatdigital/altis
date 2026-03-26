import Foundation
import _Concurrency

/// Feature flow for the Kanban Board presentation.
///
/// Owns `KanbanBoardFeatureState` and processes `KanbanBoardFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded and mutations persisted via `OfflineKanbanDataWorker`.
/// - `online` boards: access gated by `OnlineBoardAuthGateContract`; reads and
///   writes go through `OnlineBoardGatewayContract`.
@MainActor
final class KanbanBoardFeatureFlow: ObservableObject {

    @Published private(set) var state = KanbanBoardFeatureState()

    private let offlineWorker: OfflineKanbanDataWorker
    private let onlineAuthGate: OnlineBoardAuthGateContract
    private let onlineGateway: OnlineBoardGatewayContract
    private var activeTasks: [_Concurrency.Task<Void, Never>] = []

    init(
        offlineWorker: OfflineKanbanDataWorker,
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

        case .taskCompleteRequested(let taskId):
            guard let boardId = state.boardId else { break }
            terminalAction(taskId: taskId, boardId: boardId, isComplete: true)

        case .taskFailRequested(let taskId):
            guard let boardId = state.boardId else { break }
            terminalAction(taskId: taskId, boardId: boardId, isComplete: false)

        case .offlineColumnsLoaded(let columns):
            state.onlineUnavailable = nil
            state.errorMessage = nil
            state.columns = columns
            state.isLoading = false

        case .onlineColumnsLoaded(let columns):
            state.onlineUnavailable = nil
            state.errorMessage = nil
            state.columns = columns
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.columns = []
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
            mutateOnlineBoard(boardId: boardId) {
                _ = try await self.onlineGateway.moveTask(.init(
                    taskId: taskId,
                    boardId: boardId,
                    destinationStageId: toStageId
                ))
            }
        }
    }

    private func terminalAction(taskId: TaskID, boardId: BoardID, isComplete: Bool) {
        switch state.boardMode {
        case .offline:
            spawnTask {
                do {
                    if isComplete {
                        try await self.offlineWorker.completeTask(taskId: taskId, boardId: boardId)
                    } else {
                        try await self.offlineWorker.failTask(taskId: taskId, boardId: boardId)
                    }
                    guard !_Concurrency.Task.isCancelled else { return }
                    let columns = try await self.offlineWorker.loadColumns(boardId: boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineColumnsLoaded(columns))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.loadFailed(error))
                }
            }
        case .online:
            mutateOnlineBoard(boardId: boardId) {
                _ = try await self.onlineGateway.applyTerminalAction(.init(
                    taskId: taskId,
                    boardId: boardId,
                    resolution: isComplete ? .completed : .failed
                ))
            }
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
            spawnTask {
                do {
                    try await self.onlineAuthGate.requireAccess()
                    let content = try await self.onlineGateway.fetchBoardContent(boardId: boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.onlineColumnsLoaded(KanbanColumnProjection.onlineColumns(content: content)))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.onlineUnavailable(OnlineBoardUnavailableReason(error: error)))
                }
            }
        }
    }

    private func mutateOnlineBoard(
        boardId: BoardID,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        state.isLoading = true
        spawnTask {
            do {
                try await self.onlineAuthGate.requireAccess()
                try await operation()
                let content = try await self.onlineGateway.fetchBoardContent(boardId: boardId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.onlineColumnsLoaded(KanbanColumnProjection.onlineColumns(content: content)))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.onlineUnavailable(OnlineBoardUnavailableReason(error: error)))
            }
        }
    }
}
