import Foundation

/// Flat SQLite-row representation of a `BoardStage` domain entity.
///
/// Column mapping (one row per stage):
/// - `stageId`       TEXT PRIMARY KEY
/// - `boardId`       TEXT NOT NULL
/// - `name`          TEXT NOT NULL
/// - `orderIndex`    INTEGER NOT NULL
/// - `kind`          TEXT NOT NULL   (raw value of `BoardStageKind`)
/// - `createdAt`     TEXT NOT NULL   (ISO-8601)
/// - `updatedAt`     TEXT NOT NULL   (ISO-8601)
struct BoardStageRecord: PersistenceRecord {

    var stageId: String
    var boardId: String
    var name: String
    var orderIndex: Int
    /// Raw value of `BoardStageKind`: `"regular"`, `"terminalSuccess"`, `"terminalFailure"`.
    var kind: String
    var createdAt: String
    var updatedAt: String
}

// MARK: - Domain mapping

extension BoardStageRecord {

    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    /// Creates a persistence record from a `BoardStage` domain value.
    init(from stage: BoardStage) {
        self.stageId = stage.stageId.rawValue
        self.boardId = stage.boardId.rawValue
        self.name = stage.name
        self.orderIndex = stage.orderIndex
        self.kind = stage.kind.rawValue
        self.createdAt = Self.iso.string(from: stage.createdAt)
        self.updatedAt = Self.iso.string(from: stage.updatedAt)
    }

    /// Converts this record back to a `BoardStage` domain value.
    ///
    /// Returns `nil` when any required date string cannot be parsed, or when the
    /// stored `kind` string is not a known `BoardStageKind` raw value.
    func toDomain() -> BoardStage? {
        guard
            let created = Self.iso.date(from: createdAt),
            let updated = Self.iso.date(from: updatedAt),
            let stageKind = BoardStageKind(rawValue: kind)
        else { return nil }

        return BoardStage(
            stageId: BoardStageID(rawValue: stageId),
            boardId: BoardID(rawValue: boardId),
            name: name,
            orderIndex: orderIndex,
            kind: stageKind,
            createdAt: created,
            updatedAt: updated
        )
    }
}
