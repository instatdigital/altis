import Foundation

/// Events that the KanbanBoard feature flow can receive.
///
/// KanbanBoard shows one board in column layout. Board mode determines the
/// data authority: `offline` reads from local SQLite projections; `online`
/// reads from the backend gateway (Phase 14).
enum KanbanBoardFeatureEvent {
    // MARK: Lifecycle
    /// Emitted when the kanban page appears, carrying the active board context.
    case appeared(boardId: BoardID, boardMode: BoardMode)

    // MARK: User intents — implemented in Phase 11 / Phase 12 / Phase 13
    /// User tapped a task card to open its detail page.
    case taskSelected(TaskID)
    /// User dropped a task card onto a stage column.
    case taskMoved(taskId: TaskID, toStageId: BoardStageID)
    /// User tapped the complete action on a card.
    case taskCompleteRequested(TaskID)
    /// User tapped the fail action on a card.
    case taskFailRequested(TaskID)

    // MARK: Data results
    /// Local persistence returned the column projections for the active offline board.
    case offlineColumnsLoaded([KanbanColumnProjection])
    /// Online transport returned the column projections for the active online board.
    case onlineColumnsLoaded([KanbanColumnProjection])
    /// The active board is online but the online path is unavailable.
    case onlineUnavailable(OnlineBoardUnavailableReason)
    /// A data operation failed.
    case loadFailed(Error)
}
