import Foundation

protocol OnlineBoardAuthGateContract: Sendable {
    func requireAccess() async throws
}

/// Contract for online-board transport operations.
///
/// Online boards are backend-only. No local durable storage is used.
/// When the network or auth is unavailable, callers receive a thrown error and
/// the feature flow surfaces an unavailable state — they do NOT fall back to
/// local writes or silently swallow the failure.
///
/// This protocol is the cross-platform canonical client-side boundary for
/// backend communication. It lives in `shared/contracts/` so all Apple
/// platforms consume one definition. Platform-specific implementations are
/// injected at the app shell level; feature flows depend only on this interface.
///
/// Phase 14 provides concrete implementations.
protocol OnlineBoardGatewayContract: Sendable {

    // MARK: - Board reads

    /// Returns all online boards for the given project.
    func fetchBoards(projectId: ProjectID) async throws -> [OnlineBoardReadModel]

    /// Returns the ordered stage list and board-scoped tasks for one online board.
    func fetchBoardContent(boardId: BoardID) async throws -> OnlineBoardContentReadModel

    // MARK: - Task reads

    /// Returns the detail of one online task.
    func fetchTask(taskId: TaskID) async throws -> OnlineTaskReadModel

    // MARK: - Task writes

    /// Moves a task to the specified stage on an online board.
    func moveTask(_ request: OnlineTaskStageMoveWriteModel) async throws -> OnlineTaskReadModel

    /// Applies a terminal task action on an online board.
    func applyTerminalAction(_ request: OnlineTaskTerminalActionWriteModel) async throws -> OnlineTaskReadModel
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

struct OnlineBoardStageReadModel: Sendable {
    let stageId: BoardStageID
    let boardId: BoardID
    let name: String
    let orderIndex: Int
    let kind: BoardStageKind
    let createdAt: Date
    let updatedAt: Date
}

struct OnlineBoardContentReadModel: Sendable {
    let boardId: BoardID
    let projectId: ProjectID
    let stages: [OnlineBoardStageReadModel]
    let tasks: [OnlineTaskReadModel]
}

/// Lightweight transport read model for an online task.
///
/// Maps to the API response shape. Feature flows MUST map this into a typed
/// projection before rendering.
struct OnlineTaskReadModel: Sendable {
    let taskId: TaskID
    let projectId: ProjectID
    let boardId: BoardID
    let stageId: BoardStageID?
    let title: String
    let status: TaskStatus
    let createdAt: Date
    let updatedAt: Date
}

struct OnlineTaskStageMoveWriteModel: Sendable {
    let taskId: TaskID
    let boardId: BoardID
    let destinationStageId: BoardStageID
}

enum OnlineTaskTerminalResolution: Sendable {
    case completed
    case failed
}

struct OnlineTaskTerminalActionWriteModel: Sendable {
    let taskId: TaskID
    let boardId: BoardID
    let resolution: OnlineTaskTerminalResolution
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

extension BoardStage {
    init(onlineStage: OnlineBoardStageReadModel) {
        self.stageId = onlineStage.stageId
        self.boardId = onlineStage.boardId
        self.name = onlineStage.name
        self.orderIndex = onlineStage.orderIndex
        self.kind = onlineStage.kind
        self.createdAt = onlineStage.createdAt
        self.updatedAt = onlineStage.updatedAt
    }
}

extension TaskListItemProjection {
    init(onlineTask: OnlineTaskReadModel, stages: [OnlineBoardStageReadModel]) {
        let currentStage = onlineTask.stageId.flatMap { stageId in
            stages.first(where: { $0.stageId == stageId })
        }
        self.taskId = onlineTask.taskId
        self.title = onlineTask.title
        self.status = onlineTask.status
        self.stageName = currentStage?.name
        self.stageKind = currentStage?.kind
        self.stageOrderIndex = currentStage?.orderIndex
        self.totalStageCount = stages.count
    }
}

extension TaskDetailProjection {
    init(onlineTask: OnlineTaskReadModel, stages: [OnlineBoardStageReadModel]) {
        let boardStages = stages
            .sorted(by: { $0.orderIndex < $1.orderIndex })
            .map(BoardStage.init(onlineStage:))
        self.taskId = onlineTask.taskId
        self.title = onlineTask.title
        self.status = onlineTask.status
        self.boardStages = boardStages
        self.currentStage = onlineTask.stageId.flatMap { stageId in
            boardStages.first(where: { $0.stageId == stageId })
        }
        self.projectId = onlineTask.projectId
        self.boardId = onlineTask.boardId
        self.createdAt = onlineTask.createdAt
        self.updatedAt = onlineTask.updatedAt
    }
}

extension KanbanColumnProjection {
    static func onlineColumns(content: OnlineBoardContentReadModel) -> [KanbanColumnProjection] {
        let orderedStages = content.stages.sorted(by: { $0.orderIndex < $1.orderIndex })
        return orderedStages.map { stage in
            let tasks = content.tasks
                .filter { $0.stageId == stage.stageId }
                .map { TaskListItemProjection(onlineTask: $0, stages: orderedStages) }
            return KanbanColumnProjection(
                stageId: stage.stageId,
                stageName: stage.name,
                stageKind: stage.kind,
                tasks: tasks
            )
        }
    }
}
