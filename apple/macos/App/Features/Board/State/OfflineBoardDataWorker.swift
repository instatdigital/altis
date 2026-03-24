import Foundation

/// Isolated data-access boundary for offline board persistence.
///
/// Covers only `offline` boards whose durable source of truth is local SQLite.
/// The real implementation is added in Phase 7 when the offline board flow is built.
///
/// Rules (from `docs/SYNC_RULES.md`):
/// - Offline board writes MUST stay local-only.
/// - Data workers MUST encapsulate data access behind typed interfaces.
protocol OfflineBoardDataWorker: Sendable {
    /// Returns typed list projections for all offline boards in the given project.
    ///
    /// Returns projections (not raw domain entities) so that store-computed
    /// fields such as `stageCount` reach the feature flow intact.
    func loadBoards(projectId: ProjectID) async throws -> [BoardListItemProjection]

    /// Persists a new offline board with default stage invariants and returns the saved entity.
    func createBoard(name: String, projectId: ProjectID, workspaceId: WorkspaceID) async throws -> Board

    /// Persists a new offline board by copying stages from a preset.
    func createBoardFromPreset(
        name: String,
        projectId: ProjectID,
        workspaceId: WorkspaceID,
        preset: BoardStagePreset,
        presetStages: [BoardStagePresetStage]
    ) async throws -> Board
}
