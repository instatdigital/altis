import Foundation

/// Events that the TaskPage feature flow can receive.
///
/// TaskPage shows the full detail of one task. The task's owning board's
/// `mode` determines which data authority is used.
enum TaskPageFeatureEvent {
    // MARK: Lifecycle
    /// Emitted when the task list page appears for a board, pre-loading stage context.
    case boardContextLoaded(boardId: BoardID, boardMode: BoardMode)
    /// Emitted when the task page appears, carrying the task to display.
    case appeared(taskId: TaskID, boardMode: BoardMode)

    // MARK: User intents — create
    /// User requested to create a new task on the given board, in the given stage.
    case createTaskRequested(title: String, boardId: BoardID, stageId: BoardStageID, workspaceId: WorkspaceID, projectId: ProjectID)

    // MARK: User intents — mutations (Phase 9 / Phase 13)
    /// User requested to move the task to a different stage.
    case stageMoveRequested(stageId: BoardStageID)
    /// User tapped the complete action.
    case completeRequested
    /// User tapped the fail action.
    case failRequested
    /// User acknowledged an error alert.
    case errorAcknowledged

    // MARK: Data results
    /// Local persistence returned the detail projection for the active offline task.
    case offlineTaskLoaded(TaskDetailProjection)
    /// A task was successfully created and persisted.
    case taskCreated(TaskDetailProjection)
    /// The active board is online but the online path is unavailable.
    case onlineUnavailable(OnlineBoardUnavailableReason)
    /// A data operation failed.
    case loadFailed(Error)
    /// A write operation failed.
    case writeFailed(Error)
}
