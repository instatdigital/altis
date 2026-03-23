import Foundation

/// Explicit local and remote synchronization metadata attached to CRUD entities.
///
/// Keeps sync state, outbox dirty flag, and optional remote version together
/// so persistence records and domain models can always answer sync queries
/// without reaching into a separate store.
struct SyncMetadata: Hashable, Codable, Sendable {

    /// Current synchronization state of the owning entity.
    var syncState: SyncState

    /// Timestamp of the last successful sync with the backend. `nil` if never synced.
    var lastSyncedAt: Date?

    /// Opaque version token from the backend used for optimistic concurrency. `nil` if never synced.
    var remoteVersion: String?

    /// Monotonically increasing local revision counter. Incremented on every local write.
    var localRevision: Int

    /// `true` when there are uncommitted local changes that have not yet been sent to the backend.
    var isDirty: Bool

    /// Convenience initialiser for a brand-new locally created entity.
    init(
        syncState: SyncState = .pendingUpload,
        lastSyncedAt: Date? = nil,
        remoteVersion: String? = nil,
        localRevision: Int = 1,
        isDirty: Bool = true
    ) {
        self.syncState = syncState
        self.lastSyncedAt = lastSyncedAt
        self.remoteVersion = remoteVersion
        self.localRevision = localRevision
        self.isDirty = isDirty
    }
}

// MARK: - SyncState

/// Observable states of a single entity relative to the backend.
enum SyncState: String, Hashable, Codable, Sendable, CaseIterable {
    /// Entity was created locally and has never been sent to the backend.
    case pendingUpload
    /// Entity is in sync with the backend and has no local changes.
    case synced
    /// Entity has local changes that differ from the last known backend state.
    case locallyModified
    /// Entity was deleted locally but the deletion has not yet been confirmed by the backend.
    case pendingDeletion
    /// The last sync attempt for this entity resulted in an error.
    case syncError
}
