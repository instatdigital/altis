import Foundation

/// Canonical work item rendered in task list, task detail, kanban cards, and widgets.
///
/// A task MUST belong to a workspace and a project. Board and stage membership are
/// optional: a task with a `stageId` MUST also carry a `boardId`, and that board
/// MUST belong to the same project.
struct Task: Hashable, Codable, Sendable {

    /// Stable typed identifier for this task.
    let taskId: TaskID

    /// Workspace this task belongs to.
    let workspaceId: WorkspaceID

    /// Project this task belongs to.
    let projectId: ProjectID

    /// Board this task belongs to. `nil` if the task is not on any board.
    var boardId: BoardID?

    /// Current stage on the owning board. `nil` when `boardId` is `nil`.
    /// When non-nil, the stage MUST belong to the board identified by `boardId`.
    var stageId: BoardStageID?

    /// Short user-visible description of the work to be done.
    var title: String

    /// High-level completion status. Kept compatible with board terminal outcomes.
    var status: TaskStatus

    /// UTC timestamp of when this task was created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to any field on this task.
    var updatedAt: Date

    /// UTC timestamp of the most recent content modification.
    /// Used as the tie-breaker during sync's latest-version replacement strategy.
    var lastModifiedAt: Date

    /// Local and remote synchronization state for this task.
    var syncMetadata: SyncMetadata

    init(
        taskId: TaskID = TaskID(),
        workspaceId: WorkspaceID,
        projectId: ProjectID,
        boardId: BoardID? = nil,
        stageId: BoardStageID? = nil,
        title: String,
        status: TaskStatus = .open,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastModifiedAt: Date = Date(),
        syncMetadata: SyncMetadata = SyncMetadata()
    ) {
        self.taskId = taskId
        self.workspaceId = workspaceId
        self.projectId = projectId
        self.boardId = boardId
        self.stageId = stageId
        self.title = title
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastModifiedAt = lastModifiedAt
        self.syncMetadata = syncMetadata
    }
}

// MARK: - TaskStatus

/// High-level lifecycle state of a task.
///
/// When a task belongs to a staged board, transitions to `completed` or `failed`
/// MUST also move the task into the corresponding terminal `BoardStage`.
enum TaskStatus: String, Hashable, Codable, Sendable {
    /// Task is active and not yet resolved.
    case open
    /// Task was completed successfully. Aligns with `BoardStageKind.terminalSuccess`.
    case completed
    /// Task was abandoned or failed. Aligns with `BoardStageKind.terminalFailure`.
    case failed
}
