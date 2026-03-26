import Foundation

/// Typed route definitions for top-level app navigation.
enum AppRoute: Hashable {
    case home
    case project
    /// Shows the board list for the given project.
    case boardList(projectId: ProjectID, workspaceId: WorkspaceID)
    /// Shows the task list for an offline board.
    case taskList(boardId: BoardID, boardMode: BoardMode)
    case kanbanBoard
    /// Shows the full detail page for a task.
    case taskPage(taskId: TaskID, boardMode: BoardMode)
}
