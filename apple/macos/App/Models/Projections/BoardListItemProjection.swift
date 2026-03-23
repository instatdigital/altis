import Foundation

/// UI read model for a single row in the board list.
///
/// Derived from the `Board` domain entity. Does not expose `syncMetadata`
/// to views; sync state is surfaced only where explicitly required.
struct BoardListItemProjection: Hashable, Sendable {

    /// Stable identifier for navigation and diffing.
    let boardId: BoardID

    /// Owning project identifier, used for navigation context.
    let projectId: ProjectID

    /// User-visible board name.
    let name: String

    /// Total number of stages on this board. Computed on read.
    let stageCount: Int

    /// Total number of non-deleted tasks on this board. Computed on read.
    let taskCount: Int
}

// MARK: - Domain mapping

extension BoardListItemProjection {

    /// Creates a projection from a domain `Board` and its aggregate counts.
    init(board: Board, stageCount: Int, taskCount: Int) {
        self.boardId = board.boardId
        self.projectId = board.projectId
        self.name = board.name
        self.stageCount = stageCount
        self.taskCount = taskCount
    }
}
