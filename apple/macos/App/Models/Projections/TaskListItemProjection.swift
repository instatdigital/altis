import Foundation

/// UI read model for a single row in the task list or kanban card.
///
/// Carries the minimum fields required to render a task in list mode and as
/// a kanban card. For full task detail, use `TaskDetailProjection`.
struct TaskListItemProjection: Hashable, Sendable {

    /// Stable identifier for navigation and diffing.
    let taskId: TaskID

    /// User-visible task title.
    let title: String

    /// High-level lifecycle status.
    let status: TaskStatus

    /// Name of the current board stage, if the task is on a board.
    let stageName: String?

    /// Semantic kind of the current stage, used to apply terminal styling.
    let stageKind: BoardStageKind?

    /// Zero-based position of the current stage among all board stages.
    /// `nil` when the task is not on a board.
    let stageOrderIndex: Int?

    /// Total number of stages on the owning board.
    /// `nil` when the task is not on a board.
    let totalStageCount: Int?
}

// MARK: - Domain mapping

extension TaskListItemProjection {

    /// Creates a projection from a task and its optional current stage context.
    init(task: Task, currentStage: BoardStage?, totalStageCount: Int?) {
        self.taskId = task.taskId
        self.title = task.title
        self.status = task.status
        self.stageName = currentStage?.name
        self.stageKind = currentStage?.kind
        self.stageOrderIndex = currentStage?.orderIndex
        self.totalStageCount = totalStageCount
    }
}
