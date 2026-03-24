import Foundation

/// Isolated data-access boundary for the offline kanban board.
///
/// Used by `KanbanBoardFeatureFlow` when the active board mode is `.offline`.
/// The real implementation is added in Phase 11 (read) and Phase 12 (moves).
///
/// Rules (from `docs/SYNC_RULES.md`):
/// - Offline board surfaces MUST render from local typed projections.
/// - Offline board writes MUST stay local-only.
/// - Data workers MUST encapsulate data access behind typed interfaces.
protocol OfflineKanbanDataWorker: Sendable {
    /// Returns kanban column projections for the given offline board in `orderIndex` order.
    func loadColumns(boardId: BoardID) async throws -> [KanbanColumnProjection]

    /// Moves a task to a different stage and persists the change locally.
    func moveTask(taskId: TaskID, toStageId: BoardStageID, boardId: BoardID) async throws

    /// Moves a task to the board's terminal success stage.
    func completeTask(taskId: TaskID, boardId: BoardID) async throws

    /// Moves a task to the board's terminal failure stage.
    func failTask(taskId: TaskID, boardId: BoardID) async throws
}
