import Foundation

/// Flat persistence representation of `SyncMetadata`.
///
/// Embedded as columns inside every entity record rather than stored in a
/// separate table, so each entity row is self-contained and can be loaded
/// without a join.
struct SyncMetadataRecord: PersistenceRecord {

    /// Raw string of `SyncState` (`pendingUpload`, `synced`, etc.).
    var syncState: String

    /// ISO-8601 string of last successful sync timestamp. `nil` if never synced.
    var lastSyncedAt: String?

    /// Opaque version token from the backend. `nil` if never synced.
    var remoteVersion: String?

    /// Monotonically increasing local revision counter.
    var localRevision: Int

    /// `true` when uncommitted local changes exist.
    var isDirty: Bool
}

// MARK: - Domain mapping

extension SyncMetadataRecord {

    /// Creates a persistence record from a `SyncMetadata` domain value.
    init(from metadata: SyncMetadata) {
        self.syncState = metadata.syncState.rawValue
        self.lastSyncedAt = metadata.lastSyncedAt.map { ISO8601DateFormatter().string(from: $0) }
        self.remoteVersion = metadata.remoteVersion
        self.localRevision = metadata.localRevision
        self.isDirty = metadata.isDirty
    }

    /// Converts this record back to a `SyncMetadata` domain value.
    ///
    /// Falls back to `.syncError` when the stored `syncState` string cannot be
    /// decoded, so the entity is surfaced as needing attention rather than silently
    /// adopting an incorrect state.
    func toDomain() -> SyncMetadata {
        let state = SyncState(rawValue: syncState) ?? .syncError
        let formatter = ISO8601DateFormatter()
        let date = lastSyncedAt.flatMap { formatter.date(from: $0) }
        return SyncMetadata(
            syncState: state,
            lastSyncedAt: date,
            remoteVersion: remoteVersion,
            localRevision: localRevision,
            isDirty: isDirty
        )
    }
}
