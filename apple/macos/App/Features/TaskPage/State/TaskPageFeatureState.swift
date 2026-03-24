import Foundation

/// Render state owned by `TaskPageFeatureFlow`.
struct TaskPageFeatureState {

    /// The task being viewed. `nil` before `appeared` is processed or while loading.
    var task: TaskDetailProjection? = nil

    /// Active board mode — determines which data authority is used.
    var boardMode: BoardMode = .offline

    /// `true` while a load or write is in progress.
    var isLoading: Bool = false

    /// Non-nil when the active board is online but unavailable.
    /// Mutually exclusive with `errorMessage`.
    var onlineUnavailable: OnlineBoardUnavailableReason? = nil

    /// Non-nil when a local persistence operation produced an error.
    var errorMessage: String? = nil
}
