import Foundation
import _Concurrency

/// Feature flow for the Task Detail page and Task Creation.
///
/// Owns `TaskPageFeatureState` and processes `TaskPageFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded and mutations persisted via `OfflineTaskPageDataWorker`.
/// - `online` boards: access gated by `OnlineBoardAuthGateContract`; reads and
///   writes go through `OnlineBoardGatewayContract`.
@MainActor
final class TaskPageFeatureFlow: ObservableObject {

    @Published private(set) var state = TaskPageFeatureState()

    private let offlineWorker: OfflineTaskPageDataWorker
    private let onlineAuthGate: OnlineBoardAuthGateContract
    private let onlineGateway: OnlineBoardGatewayContract
    private let store: any LocalStoreContract & LocalWritePathContract
    private var activeTasks: [_Concurrency.Task<Void, Never>] = []

    init(
        offlineWorker: OfflineTaskPageDataWorker,
        onlineAuthGate: OnlineBoardAuthGateContract,
        onlineGateway: OnlineBoardGatewayContract,
        store: any LocalStoreContract & LocalWritePathContract
    ) {
        self.offlineWorker = offlineWorker
        self.onlineAuthGate = onlineAuthGate
        self.onlineGateway = onlineGateway
        self.store = store
    }

    deinit {
        for task in activeTasks { task.cancel() }
    }

    // MARK: - Event entry point

    func send(_ event: TaskPageFeatureEvent) {
        switch event {
        case .boardContextLoaded(let boardId, let boardMode):
            // Only cancel active tasks if the board context entirely changed. Otherwise,
            // we might be just presenting the create sheet over an existing page.
            if state.activeBoardId != boardId {
                cancelActiveTasks()
            }
            state.activeBoardId = boardId
            state.boardMode = boardMode
            loadBoardContext(boardId: boardId)

        case .appeared(let taskId, let boardMode):
            if state.task?.taskId != taskId {
                cancelActiveTasks()
                state.task = nil
                state.errorMessage = nil
                state.onlineUnavailable = nil
            }
            state.boardMode = boardMode
            loadTask(taskId: taskId, boardMode: boardMode)

        case .createTaskRequested(let title, let boardId, let stageId, let workspaceId, let projectId):
            createTask(
                title: title,
                boardId: boardId,
                stageId: stageId,
                workspaceId: workspaceId,
                projectId: projectId
            )

        case .stageMoveRequested(let stageId):
            guard let taskId = state.task?.taskId else { return }
            moveTask(taskId: taskId, toStageId: stageId)

        case .completeRequested:
            guard let taskId = state.task?.taskId else { return }
            completeTask(taskId: taskId)

        case .failRequested:
            guard let taskId = state.task?.taskId else { return }
            failTask(taskId: taskId)

        case .errorAcknowledged:
            state.errorMessage = nil

        case .offlineTaskLoaded(let projection):
            state.onlineUnavailable = nil
            state.errorMessage = nil
            state.task = projection
            state.activeBoardId = projection.boardId
            state.activeProjectId = projection.projectId
            // Refresh board stages from the loaded task projection.
            if !projection.boardStages.isEmpty {
                state.boardStages = projection.boardStages
            }
            state.isLoading = false

        case .onlineTaskLoaded(let projection):
            state.onlineUnavailable = nil
            state.errorMessage = nil
            state.task = projection
            state.activeBoardId = projection.boardId
            state.activeProjectId = projection.projectId
            // Refresh board stages from the loaded task projection.
            if !projection.boardStages.isEmpty {
                state.boardStages = projection.boardStages
            }
            state.isLoading = false

        case .taskCreated(let projection):
            state.task = projection
            state.activeBoardId = projection.boardId
            state.activeProjectId = projection.projectId
            if !projection.boardStages.isEmpty {
                state.boardStages = projection.boardStages
            }
            state.isCreating = false
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.task = nil
            state.isLoading = false
            state.onlineUnavailable = reason

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription

        case .writeFailed(let error):
            state.isCreating = false
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

    private func loadBoardContext(boardId: BoardID) {
        spawnTask {
            do {
                let stages = try await self.store.fetchBoardStages(boardId: boardId)
                guard !_Concurrency.Task.isCancelled else { return }
                // Update state with stage context for the create-task sheet.
                if let board = try await self.store.fetchBoard(id: boardId) {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.state.activeProjectId = board.projectId
                }
                self.state.boardStages = stages
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                // Non-fatal: stage context failed to load. Create sheet will be disabled.
                self.state.errorMessage = error.localizedDescription
            }
        }
    }

    private func loadTask(taskId: TaskID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            spawnTask {
                do {
                    let projection = try await self.offlineWorker.loadTask(taskId: taskId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineTaskLoaded(projection))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.loadFailed(error))
                }
            }
        case .online:
            spawnTask {
                do {
                    try await self.onlineAuthGate.requireAccess()
                    let task = try await self.onlineGateway.fetchTask(taskId: taskId)
                    let content = try await self.onlineGateway.fetchBoardContent(boardId: task.boardId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.onlineTaskLoaded(TaskDetailProjection(onlineTask: task, stages: content.stages)))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.onlineUnavailable(OnlineBoardUnavailableReason(error: error)))
                }
            }
        }
    }

    private func createTask(
        title: String,
        boardId: BoardID,
        stageId: BoardStageID,
        workspaceId: WorkspaceID,
        projectId: ProjectID
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.isCreating = true

        spawnTask {
            do {
                let now = Date()
                let task = Task(
                    workspaceId: workspaceId,
                    projectId: projectId,
                    boardId: boardId,
                    stageId: stageId,
                    title: trimmed,
                    createdAt: now,
                    updatedAt: now
                )
                try await self.store.createTask(task)
                guard !_Concurrency.Task.isCancelled else { return }
                let projection = try await self.offlineWorker.loadTask(taskId: task.taskId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.taskCreated(projection))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.writeFailed(error))
            }
        }
    }

    private func moveTask(taskId: TaskID, toStageId: BoardStageID) {
        state.isLoading = true
        switch state.boardMode {
        case .offline:
            spawnTask {
                do {
                    let projection = try await self.offlineWorker.moveTask(taskId: taskId, toStageId: toStageId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineTaskLoaded(projection))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.writeFailed(error))
                }
            }
        case .online:
            guard let boardId = state.task?.boardId else {
                send(.onlineUnavailable(.networkUnavailable))
                return
            }
            mutateOnlineTask(taskId: taskId, boardId: boardId) {
                _ = try await self.onlineGateway.moveTask(.init(
                    taskId: taskId,
                    boardId: boardId,
                    destinationStageId: toStageId
                ))
            }
        }
    }

    private func completeTask(taskId: TaskID) {
        state.isLoading = true
        switch state.boardMode {
        case .offline:
            spawnTask {
                do {
                    let projection = try await self.offlineWorker.completeTask(taskId: taskId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineTaskLoaded(projection))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.writeFailed(error))
                }
            }
        case .online:
            guard let boardId = state.task?.boardId else {
                send(.onlineUnavailable(.networkUnavailable))
                return
            }
            mutateOnlineTask(taskId: taskId, boardId: boardId) {
                _ = try await self.onlineGateway.applyTerminalAction(.init(
                    taskId: taskId,
                    boardId: boardId,
                    resolution: .completed
                ))
            }
        }
    }

    private func failTask(taskId: TaskID) {
        state.isLoading = true
        switch state.boardMode {
        case .offline:
            spawnTask {
                do {
                    let projection = try await self.offlineWorker.failTask(taskId: taskId)
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.offlineTaskLoaded(projection))
                } catch {
                    guard !_Concurrency.Task.isCancelled else { return }
                    self.send(.writeFailed(error))
                }
            }
        case .online:
            guard let boardId = state.task?.boardId else {
                send(.onlineUnavailable(.networkUnavailable))
                return
            }
            mutateOnlineTask(taskId: taskId, boardId: boardId) {
                _ = try await self.onlineGateway.applyTerminalAction(.init(
                    taskId: taskId,
                    boardId: boardId,
                    resolution: .failed
                ))
            }
        }
    }

    private func mutateOnlineTask(
        taskId: TaskID,
        boardId: BoardID,
        operation: @escaping @Sendable () async throws -> Void
    ) {
        spawnTask {
            do {
                try await self.onlineAuthGate.requireAccess()
                try await operation()
                let task = try await self.onlineGateway.fetchTask(taskId: taskId)
                let content = try await self.onlineGateway.fetchBoardContent(boardId: boardId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.onlineTaskLoaded(TaskDetailProjection(onlineTask: task, stages: content.stages)))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.onlineUnavailable(OnlineBoardUnavailableReason(error: error)))
            }
        }
    }
}
