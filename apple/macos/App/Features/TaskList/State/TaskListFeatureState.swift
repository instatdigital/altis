import Foundation

/// Render state owned by `TaskListFeatureFlow`.
struct TaskListFeatureState {

    /// The board context currently shown. `nil` before `appeared` is processed.
    var boardId: BoardID? = nil

    /// Active board mode — determines which data authority is used.
    var boardMode: BoardMode = .offline

    /// Task rows shown in the list. Empty until Phase 10 loads data.
    var tasks: [TaskListItemProjection] = []

    /// `true` while a load is in progress.
    var isLoading: Bool = false

    /// Non-nil when the active board is online but unavailable.
    /// Mutually exclusive with `errorMessage`.
    var onlineUnavailable: OnlineBoardUnavailableReason? = nil

    /// Non-nil when a local persistence operation produced an error.
    var errorMessage: String? = nil
}
