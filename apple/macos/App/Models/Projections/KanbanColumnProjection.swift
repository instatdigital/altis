import Foundation

/// UI read model for a single column in the kanban board.
///
/// One `KanbanColumnProjection` maps to one `BoardStage`. The kanban page builds
/// its column list by fetching these projections in `orderIndex` order.
struct KanbanColumnProjection: Hashable, Sendable, Identifiable {

    var id: BoardStageID { stageId }

    /// Stage identifier used for drop-target routing.
    let stageId: BoardStageID

    /// Column header label.
    let stageName: String

    /// Semantic kind drives terminal column styling.
    let stageKind: BoardStageKind

    /// Tasks currently assigned to this stage, in insertion order.
    let tasks: [TaskListItemProjection]
}

// MARK: - Domain mapping

extension KanbanColumnProjection {

    /// Creates a column projection from a stage and its assigned tasks.
    ///
    /// - Parameters:
    ///   - stage: The `BoardStage` this column represents.
    ///   - tasks: All task projections assigned to this stage, in the desired display order.
    ///   - totalStageCount: Total number of stages on the board, used for stage-progress line rendering.
    init(stage: BoardStage, tasks: [Task], totalStageCount: Int) {
        self.stageId = stage.stageId
        self.stageName = stage.name
        self.stageKind = stage.kind
        self.tasks = tasks.map { task in
            TaskListItemProjection(task: task, currentStage: stage, totalStageCount: totalStageCount)
        }
    }
}
