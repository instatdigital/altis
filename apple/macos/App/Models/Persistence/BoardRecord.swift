import Foundation

/// Flat SQLite-row representation of a `Board` domain entity.
///
/// Column mapping (one row per board):
/// - `boardId`       TEXT PRIMARY KEY
/// - `workspaceId`   TEXT NOT NULL
/// - `projectId`     TEXT NOT NULL
/// - `name`          TEXT NOT NULL
/// - `mode`          TEXT NOT NULL   (raw value of `BoardMode`: `"offline"` or `"online"`)
/// - `createdAt`     TEXT NOT NULL  (ISO-8601)
/// - `updatedAt`     TEXT NOT NULL  (ISO-8601)
struct BoardRecord: PersistenceRecord {

    var boardId: String
    var workspaceId: String
    var projectId: String
    var name: String
    /// Raw value of `BoardMode`: `"offline"` or `"online"`.
    var mode: String
    var createdAt: String
    var updatedAt: String
}

// MARK: - Domain mapping

extension BoardRecord {

    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    /// Creates a persistence record from a `Board` domain value.
    init(from board: Board) {
        self.boardId = board.boardId.rawValue
        self.workspaceId = board.workspaceId.rawValue
        self.projectId = board.projectId.rawValue
        self.name = board.name
        self.mode = board.mode.rawValue
        self.createdAt = Self.iso.string(from: board.createdAt)
        self.updatedAt = Self.iso.string(from: board.updatedAt)
    }

    /// Converts this record back to a `Board` domain value.
    ///
    /// Returns `nil` when any required date string cannot be parsed, or when the
    /// stored `mode` string is not a known `BoardMode` raw value.
    func toDomain() -> Board? {
        guard
            let created = Self.iso.date(from: createdAt),
            let updated = Self.iso.date(from: updatedAt),
            let boardMode = BoardMode(rawValue: mode)
        else { return nil }

        return Board(
            boardId: BoardID(rawValue: boardId),
            workspaceId: WorkspaceID(rawValue: workspaceId),
            projectId: ProjectID(rawValue: projectId),
            name: name,
            mode: boardMode,
            createdAt: created,
            updatedAt: updated
        )
    }
}
