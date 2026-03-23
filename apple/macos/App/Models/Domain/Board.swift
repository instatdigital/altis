import Foundation

/// Workflow grouping for tasks inside a project.
///
/// A board owns an ordered set of `BoardStage` entities and imposes the stage
/// invariants defined in `docs/TYPES_AND_CONTRACTS.md`:
/// - at least three stages
/// - exactly one terminalSuccess stage
/// - exactly one terminalFailure stage
///
/// The `mode` field determines storage authority for the board and all its
/// owned entities. See `BoardMode` for the full contract.
struct Board: Hashable, Codable, Sendable {

    /// Stable typed identifier for this board.
    let boardId: BoardID

    /// Workspace this board belongs to (must match `project.workspaceId`).
    let workspaceId: WorkspaceID

    /// Project this board belongs to.
    let projectId: ProjectID

    /// Display name shown in board lists and navigation.
    var name: String

    /// Storage authority for this board and its owned entities.
    var mode: BoardMode

    /// UTC timestamp of when this board was created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to this board.
    var updatedAt: Date

    init(
        boardId: BoardID = BoardID(),
        workspaceId: WorkspaceID,
        projectId: ProjectID,
        name: String,
        mode: BoardMode = .offline,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.boardId = boardId
        self.workspaceId = workspaceId
        self.projectId = projectId
        self.name = name
        self.mode = mode
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
