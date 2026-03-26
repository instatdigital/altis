import Foundation

/// Contract for reading typed projections from the local persistence store.
///
/// Feature flows MUST read from this interface rather than querying SQLite
/// directly. UI-facing read methods return typed projections, not raw domain
/// entities. Raw domain entity reads are provided only for internal use by
/// feature flows that need the full entity for write operations.
///
/// Rules (from `docs/SYNC_RULES.md`):
/// - UI MUST read from local typed projections only.
/// - Offline-board features read from this local store.
/// - Online-board features read from feature-owned online state or online read models.
///
/// Canonical specification: `shared/persistence/LocalStoreContract.swift`
/// The concrete implementation is injected at the app shell level.
protocol LocalStoreContract: Sendable {

    // MARK: - UI projection reads (feature state consumers)

    /// Returns all non-deleted projects in a workspace as list item projections,
    /// ordered by name, with board counts pre-computed.
    func fetchProjectListItems(workspaceId: WorkspaceID) async throws -> [ProjectListItemProjection]

    /// Returns all non-deleted boards in a project as list item projections,
    /// ordered by name, with stage and task counts pre-computed.
    func fetchBoardListItems(projectId: ProjectID) async throws -> [BoardListItemProjection]

    /// Returns ordered kanban columns for a board, each containing its task projections.
    ///
    /// Columns are ordered by stage `orderIndex`. Tasks within each column
    /// are ordered by `createdAt` descending.
    func fetchKanbanColumns(boardId: BoardID) async throws -> [KanbanColumnProjection]

    /// Returns all non-deleted tasks on a board as list item projections,
    /// ordered by `createdAt` descending. Includes current stage context.
    func fetchTaskListItems(boardId: BoardID) async throws -> [TaskListItemProjection]

    /// Returns the full task detail projection for the task page.
    ///
    /// Returns `nil` when the task is not found.
    func fetchTaskDetail(taskId: TaskID) async throws -> TaskDetailProjection?

    // MARK: - Raw domain entity reads (write-path and internal use only)

    /// Returns the raw `Project` domain entity. Use only in write-path flows.
    func fetchProject(id: ProjectID) async throws -> Project?

    /// Returns the raw `Board` domain entity. Use only in write-path flows.
    func fetchBoard(id: BoardID) async throws -> Board?

    /// Returns all non-deleted stages for a board in `orderIndex` order.
    /// Use in write-path flows (e.g. invariant validation before stage mutation).
    func fetchBoardStages(boardId: BoardID) async throws -> [BoardStage]

    /// Returns all non-deleted preset stage definitions for a preset in `orderIndex` order.
    func fetchBoardStagePresetStages(stagePresetId: BoardStagePresetID) async throws -> [BoardStagePresetStage]

    /// Returns all non-deleted presets for a workspace, ordered by name.
    func fetchBoardStagePresets(workspaceId: WorkspaceID) async throws -> [BoardStagePreset]

    /// Returns the raw `Task` domain entity. Use only in write-path flows.
    func fetchTask(id: TaskID) async throws -> Task?
}
