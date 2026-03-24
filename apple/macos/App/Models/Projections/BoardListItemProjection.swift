import Foundation

/// UI read model for a single row in the board list.
///
/// Derived from the `Board` domain entity. `mode` is exposed here so the
/// board list page can badge offline vs online boards and route navigation
/// to the correct data authority when a board is opened.
struct BoardListItemProjection: Hashable, Sendable {

    /// Stable identifier for navigation and diffing.
    let boardId: BoardID

    /// Owning project identifier, used for navigation context.
    let projectId: ProjectID

    /// User-visible board name.
    let name: String

    /// Storage authority for this board. Drives offline/online badge and routing.
    let mode: BoardMode

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
        self.mode = board.mode
        self.stageCount = stageCount
        self.taskCount = taskCount
    }
}
