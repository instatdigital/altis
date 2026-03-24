import Foundation

/// Events that the Project feature flow can receive.
enum ProjectFeatureEvent {
    // MARK: Lifecycle
    /// Emitted when the project list page appears for the first time or after navigation back.
    case appeared

    // MARK: User intents — implemented in Phase 6
    /// User requested creation of a new project with the given name.
    case createProjectRequested(name: String)
    /// User selected a project to navigate into.
    case projectSelected(ProjectID)

    // MARK: Data results — implemented in Phase 6
    /// Local persistence returned the current project list.
    case projectsLoaded([Project])
    /// Local persistence returned an error while loading or saving projects.
    case loadFailed(Error)
}
