import Foundation

/// Flat SQLite-row representation of a `Task` domain entity.
///
/// Column mapping (one row per task):
/// - `taskId`        TEXT PRIMARY KEY
/// - `workspaceId`   TEXT NOT NULL
/// - `projectId`     TEXT NOT NULL
/// - `boardId`       TEXT            (nullable FK → BoardRecord.boardId)
/// - `stageId`       TEXT            (nullable FK → BoardStageRecord.stageId)
/// - `title`         TEXT NOT NULL
/// - `status`        TEXT NOT NULL   (raw value of `TaskStatus`)
/// - `createdAt`     TEXT NOT NULL   (ISO-8601)
/// - `updatedAt`     TEXT NOT NULL   (ISO-8601)
/// - `lastModifiedAt` TEXT NOT NULL  (ISO-8601)
/// - sync columns    — from `SyncMetadataRecord` (embedded inline)
struct TaskRecord: PersistenceRecord {

    var taskId: String
    var workspaceId: String
    var projectId: String
    /// `nil` when the task is not assigned to any board.
    var boardId: String?
    /// `nil` when the task is not assigned to any stage. Non-nil requires a non-nil `boardId`.
    var stageId: String?
    var title: String
    /// Raw value of `TaskStatus`: `"open"`, `"completed"`, `"failed"`.
    var status: String
    var createdAt: String
    var updatedAt: String
    var lastModifiedAt: String

    // MARK: Embedded sync metadata columns

    var syncState: String
    var lastSyncedAt: String?
    var remoteVersion: String?
    var localRevision: Int
    var isDirty: Bool
}

// MARK: - Domain mapping

extension TaskRecord {

    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    /// Creates a persistence record from a `Task` domain value.
    init(from task: Task) {
        self.taskId = task.taskId.rawValue
        self.workspaceId = task.workspaceId.rawValue
        self.projectId = task.projectId.rawValue
        self.boardId = task.boardId?.rawValue
        self.stageId = task.stageId?.rawValue
        self.title = task.title
        self.status = task.status.rawValue
        self.createdAt = Self.iso.string(from: task.createdAt)
        self.updatedAt = Self.iso.string(from: task.updatedAt)
        self.lastModifiedAt = Self.iso.string(from: task.lastModifiedAt)

        let sync = SyncMetadataRecord(from: task.syncMetadata)
        self.syncState = sync.syncState
        self.lastSyncedAt = sync.lastSyncedAt
        self.remoteVersion = sync.remoteVersion
        self.localRevision = sync.localRevision
        self.isDirty = sync.isDirty
    }

    /// Converts this record back to a `Task` domain value.
    ///
    /// Returns `nil` when any required date string cannot be parsed, or when the
    /// stored `status` string is not a known `TaskStatus` raw value.
    func toDomain() -> Task? {
        guard
            let created = Self.iso.date(from: createdAt),
            let updated = Self.iso.date(from: updatedAt),
            let modified = Self.iso.date(from: lastModifiedAt),
            let taskStatus = TaskStatus(rawValue: status)
        else { return nil }

        let syncRecord = SyncMetadataRecord(
            syncState: syncState,
            lastSyncedAt: lastSyncedAt,
            remoteVersion: remoteVersion,
            localRevision: localRevision,
            isDirty: isDirty
        )

        return Task(
            taskId: TaskID(rawValue: taskId),
            workspaceId: WorkspaceID(rawValue: workspaceId),
            projectId: ProjectID(rawValue: projectId),
            boardId: boardId.map { BoardID(rawValue: $0) },
            stageId: stageId.map { BoardStageID(rawValue: $0) },
            title: title,
            status: taskStatus,
            createdAt: created,
            updatedAt: updated,
            lastModifiedAt: modified,
            syncMetadata: syncRecord.toDomain()
        )
    }
}
