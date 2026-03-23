import Foundation

/// Ordered workflow stage inside a board.
///
/// Stage order is governed by `orderIndex`. Terminal stages (`terminalSuccess`,
/// `terminalFailure`) MUST NOT be deleted and have special invariant enforcement
/// through `BoardStageInvariants`.
struct BoardStage: Hashable, Codable, Sendable {

    /// Stable typed identifier for this stage.
    let stageId: BoardStageID

    /// Board this stage belongs to.
    let boardId: BoardID

    /// Display name shown in kanban columns and task detail.
    var name: String

    /// Zero-based sort position within the board. Must be stable and unique per board.
    var orderIndex: Int

    /// Semantic kind of this stage. Drives terminal action rules.
    var kind: BoardStageKind

    /// UTC timestamp of when this stage was created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to this stage.
    var updatedAt: Date

    /// Local and remote synchronization state for this stage.
    var syncMetadata: SyncMetadata

    /// Convenience: whether this stage is one of the two terminal kinds.
    var isTerminal: Bool {
        kind == .terminalSuccess || kind == .terminalFailure
    }

    init(
        stageId: BoardStageID = BoardStageID(),
        boardId: BoardID,
        name: String,
        orderIndex: Int,
        kind: BoardStageKind,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        syncMetadata: SyncMetadata = SyncMetadata()
    ) {
        self.stageId = stageId
        self.boardId = boardId
        self.name = name
        self.orderIndex = orderIndex
        self.kind = kind
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.syncMetadata = syncMetadata
    }
}

// MARK: - BoardStageKind

/// Semantic classification for a board stage.
///
/// Every board must have exactly one `terminalSuccess` and one `terminalFailure` stage.
/// All other stages are `regular`.
enum BoardStageKind: String, Hashable, Codable, Sendable, CaseIterable {
    /// An ordinary in-progress stage. Multiple regular stages per board are allowed.
    case regular
    /// The unique terminal stage reached when a task is completed successfully.
    case terminalSuccess
    /// The unique terminal stage reached when a task is abandoned or failed.
    case terminalFailure
}
