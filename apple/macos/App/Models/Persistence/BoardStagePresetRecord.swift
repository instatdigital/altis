import Foundation

/// Flat SQLite-row representation of a `BoardStagePreset` domain entity.
///
/// Column mapping (one row per preset):
/// - `stagePresetId` TEXT PRIMARY KEY
/// - `workspaceId`   TEXT NOT NULL
/// - `name`          TEXT NOT NULL
/// - `createdAt`     TEXT NOT NULL  (ISO-8601)
/// - `updatedAt`     TEXT NOT NULL  (ISO-8601)
/// - sync columns    — from `SyncMetadataRecord` (embedded inline)
struct BoardStagePresetRecord: PersistenceRecord {

    var stagePresetId: String
    var workspaceId: String
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

extension BoardStagePresetRecord {

    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    /// Creates a persistence record from a `BoardStagePreset` domain value.
    init(from preset: BoardStagePreset) {
        self.stagePresetId = preset.stagePresetId.rawValue
        self.workspaceId = preset.workspaceId.rawValue
        self.name = preset.name
        self.createdAt = Self.iso.string(from: preset.createdAt)
        self.updatedAt = Self.iso.string(from: preset.updatedAt)

        let sync = SyncMetadataRecord(from: preset.syncMetadata)
        self.syncState = sync.syncState
        self.lastSyncedAt = sync.lastSyncedAt
        self.remoteVersion = sync.remoteVersion
        self.localRevision = sync.localRevision
        self.isDirty = sync.isDirty
    }

    /// Converts this record back to a `BoardStagePreset` domain value.
    ///
    /// Returns `nil` when any required date string cannot be parsed.
    func toDomain() -> BoardStagePreset? {
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

        return BoardStagePreset(
            stagePresetId: BoardStagePresetID(rawValue: stagePresetId),
            workspaceId: WorkspaceID(rawValue: workspaceId),
            name: name,
            createdAt: created,
            updatedAt: updated,
            syncMetadata: syncRecord.toDomain()
        )
    }
}

// MARK: - BoardStagePresetStageRecord

/// Flat SQLite-row representation of a `BoardStagePresetStage` sub-entity.
///
/// Preset stages are children of a `BoardStagePreset`. They carry no sync metadata
/// because they are owned by and versioned with their parent preset.
///
/// Column mapping (one row per preset stage):
/// - `presetStageId` TEXT PRIMARY KEY
/// - `stagePresetId` TEXT NOT NULL   (FK → BoardStagePresetRecord.stagePresetId)
/// - `name`          TEXT NOT NULL
/// - `orderIndex`    INTEGER NOT NULL
/// - `kind`          TEXT NOT NULL   (raw value of `BoardStageKind`)
struct BoardStagePresetStageRecord: PersistenceRecord {

    var presetStageId: String
    var stagePresetId: String
    var name: String
    var orderIndex: Int
    /// Raw value of `BoardStageKind`: `"regular"`, `"terminalSuccess"`, `"terminalFailure"`.
    var kind: String
}

// MARK: - Domain mapping

extension BoardStagePresetStageRecord {

    /// Creates a persistence record from a `BoardStagePresetStage` domain value.
    init(from presetStage: BoardStagePresetStage) {
        self.presetStageId = presetStage.presetStageId.rawValue
        self.stagePresetId = presetStage.stagePresetId.rawValue
        self.name = presetStage.name
        self.orderIndex = presetStage.orderIndex
        self.kind = presetStage.kind.rawValue
    }

    /// Converts this record back to a `BoardStagePresetStage` domain value.
    ///
    /// Returns `nil` when the stored `kind` string is not a known `BoardStageKind` raw value.
    func toDomain() -> BoardStagePresetStage? {
        guard let stageKind = BoardStageKind(rawValue: kind) else { return nil }
        return BoardStagePresetStage(
            presetStageId: BoardStagePresetStageID(rawValue: presetStageId),
            stagePresetId: BoardStagePresetID(rawValue: stagePresetId),
            name: name,
            orderIndex: orderIndex,
            kind: stageKind
        )
    }
}
