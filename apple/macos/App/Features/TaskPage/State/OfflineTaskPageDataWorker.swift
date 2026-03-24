import Foundation

/// Isolated data-access boundary for the offline task detail page.
///
/// Used by `TaskPageFeatureFlow` when the active board mode is `.offline`.
/// The real implementation is added in Phase 9 when the offline task page is built.
///
/// Rules (from `docs/SYNC_RULES.md`):
/// - Offline board surfaces MUST render from local typed projections.
/// - Offline board writes MUST stay local-only.
/// - Data workers MUST encapsulate data access behind typed interfaces.
protocol OfflineTaskPageDataWorker: Sendable {
    /// Returns the full detail projection for the given offline task.
    func loadTask(taskId: TaskID) async throws -> TaskDetailProjection

    /// Moves the task to the specified stage and persists the change locally.
    func moveTask(taskId: TaskID, toStageId: BoardStageID) async throws -> TaskDetailProjection

    /// Moves the task to the board's terminal success stage.
    func completeTask(taskId: TaskID) async throws -> TaskDetailProjection

    /// Moves the task to the board's terminal failure stage.
    func failTask(taskId: TaskID) async throws -> TaskDetailProjection
}
