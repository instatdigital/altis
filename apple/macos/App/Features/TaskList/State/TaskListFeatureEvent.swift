import Foundation

/// Events that the TaskList feature flow can receive.
///
/// TaskList always shows tasks for one board. The owning board's `mode`
/// determines which data authority is used: `offline` reads from local SQLite,
/// `online` reads from the backend gateway (Phase 14).
enum TaskListFeatureEvent {
    // MARK: Lifecycle
    /// Emitted when the task list page appears, carrying the active board context.
    case appeared(boardId: BoardID, boardMode: BoardMode)

    // MARK: User intents — implemented in Phase 9 / Phase 10
    /// User tapped a task row to open its detail page.
    case taskSelected(TaskID)

    // MARK: Data results
    /// Local persistence returned the task list projections for the active offline board.
    case offlineTasksLoaded([TaskListItemProjection])
    /// Online transport returned the task list projections for the active online board.
    case onlineTasksLoaded([TaskListItemProjection])
    /// The active board is online but the online path is unavailable.
    case onlineUnavailable(OnlineBoardUnavailableReason)
    /// A data operation failed.
    case loadFailed(Error)
}
