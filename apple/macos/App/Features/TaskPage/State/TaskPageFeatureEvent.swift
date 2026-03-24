import Foundation

/// Events that the TaskPage feature flow can receive.
///
/// TaskPage shows the full detail of one task. The task's owning board's
/// `mode` determines which data authority is used.
enum TaskPageFeatureEvent {
    // MARK: Lifecycle
    /// Emitted when the task page appears, carrying the task to display.
    case appeared(taskId: TaskID, boardMode: BoardMode)

    // MARK: User intents — implemented in Phase 9 / Phase 13
    /// User requested to move the task to a different stage.
    case stageMoveRequested(stageId: BoardStageID)
    /// User tapped the complete action.
    case completeRequested
    /// User tapped the fail action.
    case failRequested

    // MARK: Data results
    /// Local persistence returned the detail projection for the active offline task.
    case offlineTaskLoaded(TaskDetailProjection)
    /// The active board is online but the online path is unavailable.
    case onlineUnavailable(OnlineBoardUnavailableReason)
    /// A data operation failed.
    case loadFailed(Error)
}
