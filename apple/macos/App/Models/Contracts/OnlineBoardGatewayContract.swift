import Foundation

/// Contract for online-board transport operations.
///
/// Online boards are backend-only. No local durable storage is used.
/// When the network or auth is unavailable, callers receive a thrown error and
/// the feature flow surfaces an unavailable state — they do NOT fall back to
/// local writes or silently swallow the failure.
///
/// This protocol is the macOS client-side boundary for backend communication.
/// Feature flows depend only on this interface; concrete implementations are
/// injected at the app shell level in Phase 14.
protocol OnlineBoardGatewayContract: Sendable {

    // MARK: - Board reads

    /// Returns all online boards for the given project.
    func fetchBoards(projectId: ProjectID) async throws -> [OnlineBoardReadModel]

    // MARK: - Task reads

    /// Returns all tasks for the given online board.
    func fetchTasks(boardId: BoardID) async throws -> [OnlineTaskReadModel]

    /// Returns the detail of one online task.
    func fetchTask(taskId: TaskID) async throws -> OnlineTaskReadModel

    // MARK: - Task writes

    /// Moves a task to the specified stage on an online board.
    func moveTask(taskId: TaskID, toStageId: BoardStageID, boardId: BoardID) async throws -> OnlineTaskReadModel

    /// Marks a task as completed on an online board.
    func completeTask(taskId: TaskID, boardId: BoardID) async throws -> OnlineTaskReadModel

    /// Marks a task as failed on an online board.
    func failTask(taskId: TaskID, boardId: BoardID) async throws -> OnlineTaskReadModel
}

// MARK: - Online read models

/// Lightweight transport read model for an online board.
///
/// Maps to the API response shape. Feature flows MUST map this into a typed
/// `BoardListItemProjection` before handing it to the view — UI MUST NOT
/// consume this struct directly.
struct OnlineBoardReadModel: Sendable {
    let boardId: BoardID
    let projectId: ProjectID
    let name: String
    let stageCount: Int
    let taskCount: Int
}

/// Lightweight transport read model for an online task.
///
/// Maps to the API response shape. Feature flows MUST map this into a typed
/// projection before rendering.
struct OnlineTaskReadModel: Sendable {
    let taskId: TaskID
    let boardId: BoardID
    let stageId: BoardStageID?
    let title: String
    let status: String
}

// MARK: - BoardListItemProjection mapping

extension BoardListItemProjection {
    /// Creates a projection from an online board transport model.
    init(onlineBoard: OnlineBoardReadModel) {
        self.boardId = onlineBoard.boardId
        self.projectId = onlineBoard.projectId
        self.name = onlineBoard.name
        self.mode = .online
        self.stageCount = onlineBoard.stageCount
        self.taskCount = onlineBoard.taskCount
    }
}
