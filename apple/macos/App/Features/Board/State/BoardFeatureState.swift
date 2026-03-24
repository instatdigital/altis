import Foundation

/// Render state owned by `BoardFeatureFlow`.
///
/// A project may contain both offline and online boards. The flow loads each
/// authority independently and merges results into `boards` as they arrive.
struct BoardFeatureState {

    /// The project whose boards are shown. `nil` before `appeared` is processed.
    var projectId: ProjectID? = nil

    /// Workspace context needed for board creation.
    var workspaceId: WorkspaceID? = nil

    /// All board projections for the active project, combining offline and online results.
    /// Offline boards appear as soon as local persistence responds.
    /// Online boards are appended when the gateway responds successfully.
    var boards: [BoardListItemProjection] = []

    /// `true` while the offline persistence load is in progress.
    var isLoadingOffline: Bool = false

    /// `true` while the online gateway load is in progress.
    var isLoadingOnline: Bool = false

    /// `true` while a board creation is in progress.
    var isCreating: Bool = false

    /// Non-nil when the online gateway call failed or the online path is known to be unavailable.
    /// Set only after the gateway call has actually been attempted and returned an error.
    /// `nil` while the online load is still in progress or has not been attempted.
    var onlineBoardsUnavailable: OnlineBoardUnavailableReason? = nil

    /// Non-nil when the offline persistence load produced an error.
    var offlineErrorMessage: String? = nil

    /// Non-nil when a board creation or other offline write produced an error.
    var errorMessage: String? = nil

    /// Available workspace presets for the board creation sheet.
    var availablePresets: [BoardStagePreset] = []
}
