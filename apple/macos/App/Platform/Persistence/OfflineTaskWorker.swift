import Foundation

/// Concrete `OfflineTaskPageDataWorker` backed by `OfflineLocalStore`.
///
/// Loads task detail and applies write mutations for offline boards.
///
/// Rules (from `docs/ARCHITECTURE.md`):
/// - Data workers MUST encapsulate data access behind typed interfaces.
/// - UI-facing code MUST NOT call persistence or transport directly.
/// - Offline board writes MUST stay local-only.
struct OfflineTaskPageWorker: OfflineTaskPageDataWorker {

    private let store: OfflineLocalStore

    init(store: OfflineLocalStore) {
        self.store = store
    }

    // MARK: - OfflineTaskPageDataWorker

    func loadTask(taskId: TaskID) async throws -> TaskDetailProjection {
        guard let projection = try await store.fetchTaskDetail(taskId: taskId) else {
            throw OfflineTaskWorkerError.taskNotFound(taskId)
        }
        return projection
    }

    func moveTask(taskId: TaskID, toStageId: BoardStageID) async throws -> TaskDetailProjection {
        guard var task = try await store.fetchTask(id: taskId) else {
            throw OfflineTaskWorkerError.taskNotFound(taskId)
        }
        guard let boardId = task.boardId else {
            throw OfflineTaskWorkerError.taskHasNoBoard(taskId)
        }
        let stages = try await store.fetchBoardStages(boardId: boardId)
        guard stages.contains(where: { $0.stageId == toStageId }) else {
            throw OfflineTaskWorkerError.stageNotFound(toStageId)
        }
        task.stageId = toStageId
        task.updatedAt = Date()
        try await store.updateTask(task)
        return TaskDetailProjection(task: task, boardStages: stages)
    }

    func completeTask(taskId: TaskID) async throws -> TaskDetailProjection {
        guard var task = try await store.fetchTask(id: taskId) else {
            throw OfflineTaskWorkerError.taskNotFound(taskId)
        }
        guard let boardId = task.boardId else {
            throw OfflineTaskWorkerError.taskHasNoBoard(taskId)
        }
        let stages = try await store.fetchBoardStages(boardId: boardId)
        guard let successStage = stages.first(where: { $0.kind == .terminalSuccess }) else {
            throw OfflineTaskWorkerError.terminalStageNotFound(boardId)
        }
        task.stageId = successStage.stageId
        task.status = .completed
        task.updatedAt = Date()
        try await store.updateTask(task)
        return TaskDetailProjection(task: task, boardStages: stages)
    }

    func failTask(taskId: TaskID) async throws -> TaskDetailProjection {
        guard var task = try await store.fetchTask(id: taskId) else {
            throw OfflineTaskWorkerError.taskNotFound(taskId)
        }
        guard let boardId = task.boardId else {
            throw OfflineTaskWorkerError.taskHasNoBoard(taskId)
        }
        let stages = try await store.fetchBoardStages(boardId: boardId)
        guard let failureStage = stages.first(where: { $0.kind == .terminalFailure }) else {
            throw OfflineTaskWorkerError.terminalStageNotFound(boardId)
        }
        task.stageId = failureStage.stageId
        task.status = .failed
        task.updatedAt = Date()
        try await store.updateTask(task)
        return TaskDetailProjection(task: task, boardStages: stages)
    }
}

/// Concrete `OfflineTaskListDataWorker` backed by `OfflineLocalStore`.
///
/// Returns typed task list projections for offline boards.
struct OfflineTaskListWorker: OfflineTaskListDataWorker {

    private let store: OfflineLocalStore

    init(store: OfflineLocalStore) {
        self.store = store
    }

    func loadTasks(boardId: BoardID) async throws -> [TaskListItemProjection] {
        try await store.fetchTaskListItems(boardId: boardId)
    }
}

// MARK: - Errors

enum OfflineTaskWorkerError: LocalizedError {
    case taskNotFound(TaskID)
    case taskHasNoBoard(TaskID)
    case stageNotFound(BoardStageID)
    case terminalStageNotFound(BoardID)

    var errorDescription: String? {
        switch self {
        case .taskNotFound(let id):
            return "Task not found: \(id.rawValue)"
        case .taskHasNoBoard(let id):
            return "Task \(id.rawValue) is not assigned to a board."
        case .stageNotFound(let id):
            return "Stage not found: \(id.rawValue)"
        case .terminalStageNotFound(let boardId):
            return "Board \(boardId.rawValue) has no terminal stage of the required kind."
        }
    }
}
