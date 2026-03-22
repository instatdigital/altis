import Foundation

/// Workflow grouping for tasks inside a project.
///
/// A board owns an ordered set of `BoardStage` entities and imposes the stage
/// invariants defined in `docs/TYPES_AND_CONTRACTS.md`:
/// - at least three stages
/// - exactly one terminalSuccess stage
/// - exactly one terminalFailure stage
struct Board: Hashable, Codable, Sendable {

    /// Stable typed identifier for this board.
    let boardId: BoardID

    /// Workspace this board belongs to (must match `project.workspaceId`).
    let workspaceId: WorkspaceID

    /// Project this board belongs to.
    let projectId: ProjectID

    /// Display name shown in board lists and navigation.
    var name: String

    /// UTC timestamp of when this board was created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to this board.
    var updatedAt: Date

    /// Local and remote synchronization state for this board.
    var syncMetadata: SyncMetadata

    init(
        boardId: BoardID = BoardID(),
        workspaceId: WorkspaceID,
        projectId: ProjectID,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncMetadata: SyncMetadata = SyncMetadata()
    ) {
        self.boardId = boardId
        self.workspaceId = workspaceId
        self.projectId = projectId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncMetadata = syncMetadata
    }
}
