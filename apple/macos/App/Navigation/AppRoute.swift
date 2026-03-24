import Foundation

/// Typed route definitions for top-level app navigation.
enum AppRoute: Hashable {
    case home
    case project
    /// Shows the board list for the given project.
    case boardList(projectId: ProjectID, workspaceId: WorkspaceID)
    case taskList
    case kanbanBoard
    case taskPage
}
