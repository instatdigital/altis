import Foundation

/// Top-level work grouping inside a workspace.
///
/// Projects are first-class navigation targets, not optional tags.
/// Every task and board belongs to exactly one project.
struct Project: Hashable, Codable, Sendable {

    /// Stable typed identifier for this project.
    let projectId: ProjectID

    /// Workspace this project belongs to.
    let workspaceId: WorkspaceID

    /// Display name shown in project lists and navigation.
    var name: String

    /// UTC timestamp of when this project was created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to this project.
    var updatedAt: Date

    init(
        projectId: ProjectID = ProjectID(),
        workspaceId: WorkspaceID,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.projectId = projectId
        self.workspaceId = workspaceId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
