import Foundation

/// Top-level scope for reusable presets and future collaboration boundaries.
///
/// A `Workspace` is the root grouping container. All projects, boards, and presets
/// belong to exactly one workspace.
struct Workspace: Hashable, Codable, Sendable {

    /// Stable typed identifier for this workspace.
    let workspaceId: WorkspaceID

    /// Display name shown in the workspace switcher and account surfaces.
    var name: String

    /// UTC timestamp of when this workspace was first created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to this workspace.
    var updatedAt: Date

    init(
        workspaceId: WorkspaceID = WorkspaceID(),
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.workspaceId = workspaceId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
