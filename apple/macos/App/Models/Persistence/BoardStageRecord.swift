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
/// - sync columns    — from `SyncMetadataRecord` (embedded inline)
struct BoardStageRecord: PersistenceRecord {

    var stageId: String
    var boardId: String
    var name: String
    var orderIndex: Int
    /// Raw value of `BoardStageKind`: `"regular"`, `"terminalSuccess"`, `"terminalFailure"`.
    var kind: String
    var createdAt: String
    var updatedAt: String

    // MARK: Embedded sync metadata columns

    var syncState: String
    var lastSyncedAt: String?
    var remoteVersion: String?
    var localRevision: Int
    var isDirty: Bool
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

        let sync = SyncMetadataRecord(from: stage.syncMetadata)
        self.syncState = sync.syncState
        self.lastSyncedAt = sync.lastSyncedAt
        self.remoteVersion = sync.remoteVersion
        self.localRevision = sync.localRevision
        self.isDirty = sync.isDirty
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

        let syncRecord = SyncMetadataRecord(
            syncState: syncState,
            lastSyncedAt: lastSyncedAt,
            remoteVersion: remoteVersion,
            localRevision: localRevision,
            isDirty: isDirty
        )

        return BoardStage(
            stageId: BoardStageID(rawValue: stageId),
            boardId: BoardID(rawValue: boardId),
            name: name,
            orderIndex: orderIndex,
            kind: stageKind,
            createdAt: created,
            updatedAt: updated,
            syncMetadata: syncRecord.toDomain()
        )
    }
}
