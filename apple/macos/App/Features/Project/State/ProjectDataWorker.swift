import Foundation

/// Isolated data-access boundary for project persistence.
///
/// The feature flow calls this protocol; it never touches the SQLite store directly.
/// The real implementation is added in Phase 6 when the offline project flow is built.
///
/// Rules (from `docs/ARCHITECTURE.md`):
/// - Data workers MUST encapsulate data access behind typed interfaces.
/// - UI-facing code MUST NOT call persistence or transport directly.
protocol ProjectDataWorker: Sendable {
    /// Returns all projects as typed list projections, ordered by name.
    ///
    /// Returns `ProjectListItemProjection` values directly so that
    /// projection-owned fields such as `boardCount` (pre-computed by the store)
    /// are preserved. The feature flow assigns these projections to state without
    /// rebuilding them from raw domain entities.
    func loadProjects() async throws -> [ProjectListItemProjection]

    /// Persists a new project and returns the saved domain entity.
    func createProject(name: String, workspaceId: WorkspaceID) async throws -> Project
}
