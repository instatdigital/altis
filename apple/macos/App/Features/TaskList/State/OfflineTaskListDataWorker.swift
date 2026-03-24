import Foundation

/// Isolated data-access boundary for reading offline task list projections.
///
/// Used by `TaskListFeatureFlow` when the active board mode is `.offline`.
/// The real implementation is added in Phase 10 when the offline task list is built.
///
/// Rules (from `docs/SYNC_RULES.md`):
/// - Offline board surfaces MUST render from local typed projections.
/// - Data workers MUST encapsulate data access behind typed interfaces.
protocol OfflineTaskListDataWorker: Sendable {
    /// Returns typed task list projections for the given offline board, ordered by creation date.
    func loadTasks(boardId: BoardID) async throws -> [TaskListItemProjection]
}
