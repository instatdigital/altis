import Foundation

/// UI read model for the full task detail page.
///
/// Extends `TaskListItemProjection` with the full ordered stage list so the
/// task page can render the compact stage-progress line and all stage names.
struct TaskDetailProjection: Hashable, Sendable {

    /// Stable identifier for the task.
    let taskId: TaskID

    /// User-visible task title.
    let title: String

    /// High-level lifecycle status.
    let status: TaskStatus

    /// All stages on the owning board in `orderIndex` order.
    /// Empty when the task is not on a board.
    let boardStages: [BoardStage]

    /// The stage the task currently occupies. `nil` when not on a board.
    let currentStage: BoardStage?

    /// Owning project identifier for breadcrumb display.
    let projectId: ProjectID

    /// Owning board identifier. `nil` when the task is not on any board.
    let boardId: BoardID?

    /// UTC creation timestamp shown in task metadata.
    let createdAt: Date

    /// UTC last-modified timestamp shown in task metadata.
    let lastModifiedAt: Date
}

// MARK: - Domain mapping

extension TaskDetailProjection {

    /// Creates a projection from a task and the full ordered stage list of its board.
    ///
    /// - Parameters:
    ///   - task: The task domain entity.
    ///   - boardStages: All stages for the task's board in `orderIndex` order.
    ///     Pass an empty array when the task is not on a board.
    init(task: Task, boardStages: [BoardStage]) {
        self.taskId = task.taskId
        self.title = task.title
        self.status = task.status
        self.boardStages = boardStages
        self.currentStage = task.stageId.flatMap { id in
            boardStages.first(where: { $0.stageId == id })
        }
        self.projectId = task.projectId
        self.boardId = task.boardId
        self.createdAt = task.createdAt
        self.lastModifiedAt = task.lastModifiedAt
    }
}
