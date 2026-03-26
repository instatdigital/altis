import Foundation

/// Render state owned by `TaskPageFeatureFlow`.
struct TaskPageFeatureState {

    /// The task being viewed. `nil` before `appeared` is processed or while loading.
    var task: TaskDetailProjection? = nil

    /// Active board mode — determines which data authority is used.
    var boardMode: BoardMode = .offline

    /// Active board identifier. Set when board context is loaded for task creation.
    var activeBoardId: BoardID? = nil

    /// Stages for the active board. Used to populate create-task stage picker.
    var boardStages: [BoardStage] = []

    /// Active project identifier for task creation context.
    var activeProjectId: ProjectID? = nil

    /// `true` while a load or write is in progress.
    var isLoading: Bool = false

    /// `true` while a task creation is in progress.
    var isCreating: Bool = false

    /// Non-nil when the active board is online but unavailable.
    /// Mutually exclusive with `errorMessage`.
    var onlineUnavailable: OnlineBoardUnavailableReason? = nil

    /// Non-nil when a persistence operation produced an error.
    var errorMessage: String? = nil
}
