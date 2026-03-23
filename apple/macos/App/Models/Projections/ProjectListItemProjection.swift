import Foundation

/// UI read model for a single row in the project list.
///
/// Derived from the `Project` domain entity. Views consume this projection;
/// they never receive the raw `Project` directly from a feature state.
struct ProjectListItemProjection: Hashable, Sendable {

    /// Stable identifier for navigation and diffing.
    let projectId: ProjectID

    /// User-visible project name.
    let name: String

    /// Number of boards inside this project. Computed on read, not stored.
    let boardCount: Int
}

// MARK: - Domain mapping

extension ProjectListItemProjection {

    /// Creates a projection from a domain `Project` and its associated board count.
    init(project: Project, boardCount: Int) {
        self.projectId = project.projectId
        self.name = project.name
        self.boardCount = boardCount
    }
}
