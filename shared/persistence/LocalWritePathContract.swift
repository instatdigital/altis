import Foundation

/// Contract for offline-board local writes.
///
/// All mutations to domain entities MUST go through this protocol. No view,
/// feature state, or service writes directly to the underlying SQLite store.
///
/// Rules (from `docs/SYNC_RULES.md`):
/// - Offline-board writes stay local-only.
/// - This contract is not used for online-board mutations.
/// - Local acceptance ends at the SQLite write; online boards use a separate gateway.
///
/// This protocol lives in `shared/persistence/` because it is a cross-platform
/// contract. The concrete SQLite implementation lives in the platform app.
/// The concrete implementation is injected at the app shell level so feature
/// flows depend only on this interface, not on SQLite directly.
protocol LocalWritePathContract: Sendable {

    // MARK: Project

    /// Persists a newly created offline project.
    func createProject(_ project: Project) async throws

    /// Persists a name change or metadata update for an existing project.
    func updateProject(_ project: Project) async throws

    /// Deletes a project locally.
    func deleteProject(id: ProjectID) async throws

    // MARK: Board

    /// Persists a newly created offline board.
    func createBoard(_ board: Board) async throws

    /// Persists a name change or metadata update for an existing board.
    func updateBoard(_ board: Board) async throws

    /// Deletes a board locally.
    func deleteBoard(id: BoardID) async throws

    // MARK: BoardStage

    /// Persists a newly created stage.
    func createBoardStage(_ stage: BoardStage) async throws

    /// Persists a rename or order change for an existing stage.
    func updateBoardStage(_ stage: BoardStage) async throws

    /// Deletes a non-terminal stage locally.
    ///
    /// Callers MUST verify `BoardStageInvariants.canDelete(stage:from:)` before
    /// calling this method. The write path does not re-validate invariants.
    func deleteBoardStage(id: BoardStageID) async throws

    // MARK: BoardStagePreset

    /// Persists a newly created preset.
    func createBoardStagePreset(_ preset: BoardStagePreset, stages: [BoardStagePresetStage]) async throws

    /// Persists an update to an existing preset header.
    func updateBoardStagePreset(_ preset: BoardStagePreset) async throws

    /// Deletes a preset locally.
    func deleteBoardStagePreset(id: BoardStagePresetID) async throws

    // MARK: Task

    /// Persists a newly created offline task.
    func createTask(_ task: Task) async throws

    /// Persists a field update for an existing task (title, stage, status, etc.).
    func updateTask(_ task: Task) async throws

    /// Deletes a task locally.
    func deleteTask(id: TaskID) async throws
}
