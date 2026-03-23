import Foundation

/// Flat SQLite-row representation of a `Project` domain entity.
///
/// Column mapping (one row per project):
/// - `projectId`     TEXT PRIMARY KEY
/// - `workspaceId`   TEXT NOT NULL
/// - `name`          TEXT NOT NULL
/// - `createdAt`     TEXT NOT NULL  (ISO-8601)
/// - `updatedAt`     TEXT NOT NULL  (ISO-8601)
struct ProjectRecord: PersistenceRecord {

    var projectId: String
    var workspaceId: String
    var name: String
    var createdAt: String
    var updatedAt: String
}

// MARK: - Domain mapping

extension ProjectRecord {

    nonisolated(unsafe) private static let iso = ISO8601DateFormatter()

    /// Creates a persistence record from a `Project` domain value.
    init(from project: Project) {
        self.projectId = project.projectId.rawValue
        self.workspaceId = project.workspaceId.rawValue
        self.name = project.name
        self.createdAt = Self.iso.string(from: project.createdAt)
        self.updatedAt = Self.iso.string(from: project.updatedAt)
    }

    /// Converts this record back to a `Project` domain value.
    ///
    /// Returns `nil` when any required date string cannot be parsed, which
    /// indicates a corrupted or migrated record that must be handled by the
    /// caller before presenting to the UI.
    func toDomain() -> Project? {
        guard
            let created = Self.iso.date(from: createdAt),
            let updated = Self.iso.date(from: updatedAt)
        else { return nil }

        return Project(
            projectId: ProjectID(rawValue: projectId),
            workspaceId: WorkspaceID(rawValue: workspaceId),
            name: name,
            createdAt: created,
            updatedAt: updated
        )
    }
}
