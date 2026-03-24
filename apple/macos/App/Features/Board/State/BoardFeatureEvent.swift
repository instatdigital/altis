import Foundation

/// Events that the Board feature flow can receive.
///
/// A project may contain both offline and online boards. This event enum
/// defines success and failure paths for both authorities so `BoardFeatureFlow`
/// can build a single typed `[BoardListItemProjection]` that represents all
/// boards in the project regardless of mode.
enum BoardFeatureEvent {
    // MARK: Lifecycle
    /// Emitted when the board list page appears, carrying the owning project and workspace.
    case appeared(projectId: ProjectID, workspaceId: WorkspaceID)

    // MARK: User intents
    /// User requested creation of a new offline board with the given name.
    case createOfflineBoardRequested(name: String, projectId: ProjectID)
    /// User requested creation of a new offline board copied from a preset.
    case createOfflineBoardFromPresetRequested(name: String, projectId: ProjectID, presetId: BoardStagePresetID)
    /// User selected a board to open.
    case boardSelected(BoardID)
    /// User dismissed an error alert.
    case errorAcknowledged

    // MARK: Offline data results
    /// Local persistence returned the offline board projections for the active project.
    case offlineBoardsLoaded([BoardListItemProjection])
    /// Local persistence failed while loading offline boards.
    case offlineLoadFailed(Error)
    /// Board creation succeeded; reload is in progress.
    case boardCreated(Board)
    /// Board creation failed.
    case boardCreateFailed(Error)
    /// Workspace presets loaded for the creation sheet.
    case presetsLoaded([BoardStagePreset])

    // MARK: Online data results
    /// The gateway returned online boards for the active project.
    case onlineBoardsLoaded([OnlineBoardReadModel])
    /// The gateway call failed or the online path is unavailable.
    case onlineBoardsFailed(OnlineBoardUnavailableReason)
}
