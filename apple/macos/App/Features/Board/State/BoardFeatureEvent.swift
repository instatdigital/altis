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
    /// User opened stage management for a specific board.
    case stageEditorRequested(BoardListItemProjection)
    /// User dismissed the stage management sheet.
    case stageEditorDismissed
    /// User requested adding a stage to the end of the board.
    case addStageRequested(boardId: BoardID, name: String)
    /// User requested renaming a stage.
    case renameStageRequested(boardId: BoardID, stageId: BoardStageID, name: String)
    /// User requested deleting a stage.
    case deleteStageRequested(boardId: BoardID, stageId: BoardStageID)
    /// User requested moving a stage to a different index.
    case moveStageRequested(boardId: BoardID, stageId: BoardStageID, destinationIndex: Int)
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
    /// Ordered stages loaded for the stage editor.
    case boardStagesLoaded(boardId: BoardID, stages: [BoardStage])
    /// Local persistence failed while loading board stages.
    case boardStagesLoadFailed(Error)
    /// A stage mutation succeeded and produced the new ordered stage list.
    case boardStagesUpdated(boardId: BoardID, stages: [BoardStage])
    /// A stage mutation failed.
    case boardStageMutationFailed(Error)

    // MARK: Online data results
    /// The gateway returned online boards for the active project.
    case onlineBoardsLoaded([OnlineBoardReadModel])
    /// The gateway call failed or the online path is unavailable.
    case onlineBoardsFailed(OnlineBoardUnavailableReason)
}
