import Foundation

/// Flat SQLite-row representation of a `Board` domain entity.
///
/// Column mapping (one row per board):
/// - `boardId`       TEXT PRIMARY KEY
/// - `workspaceId`   TEXT NOT NULL
/// - `projectId`     TEXT NOT NULL
/// - `name`          TEXT NOT NULL
/// - `createdAt`     TEXT NOT NULL  (ISO-8601)
/// - `updatedAt`     TEXT NOT NULL  (ISO-8601)
/// - sync columns    — from `SyncMetadataRecord` (embedded inline)
struct BoardRecord: PersistenceRecord {

    var boardId: String
    var workspaceId: String
    var projectId: String
    var name: String
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

extension BoardRecord {

    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    /// Creates a persistence record from a `Board` domain value.
    init(from board: Board) {
        self.boardId = board.boardId.rawValue
        self.workspaceId = board.workspaceId.rawValue
        self.projectId = board.projectId.rawValue
        self.name = board.name
        self.createdAt = Self.iso.string(from: board.createdAt)
        self.updatedAt = Self.iso.string(from: board.updatedAt)

        let sync = SyncMetadataRecord(from: board.syncMetadata)
        self.syncState = sync.syncState
        self.lastSyncedAt = sync.lastSyncedAt
        self.remoteVersion = sync.remoteVersion
        self.localRevision = sync.localRevision
        self.isDirty = sync.isDirty
    }

    /// Converts this record back to a `Board` domain value.
    ///
    /// Returns `nil` when any required date string cannot be parsed.
    func toDomain() -> Board? {
        guard
            let created = Self.iso.date(from: createdAt),
            let updated = Self.iso.date(from: updatedAt)
        else { return nil }

        let syncRecord = SyncMetadataRecord(
            syncState: syncState,
            lastSyncedAt: lastSyncedAt,
            remoteVersion: remoteVersion,
            localRevision: localRevision,
            isDirty: isDirty
        )

        return Board(
            boardId: BoardID(rawValue: boardId),
            workspaceId: WorkspaceID(rawValue: workspaceId),
            projectId: ProjectID(rawValue: projectId),
            name: name,
            createdAt: created,
            updatedAt: updated,
            syncMetadata: syncRecord.toDomain()
        )
    }
}
