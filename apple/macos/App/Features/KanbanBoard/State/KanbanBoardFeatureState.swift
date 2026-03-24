import Foundation

/// Render state owned by `KanbanBoardFeatureFlow`.
struct KanbanBoardFeatureState {

    /// The board currently shown. `nil` before `appeared` is processed.
    var boardId: BoardID? = nil

    /// Active board mode — determines which data authority is used.
    var boardMode: BoardMode = .offline

    /// Kanban columns in `orderIndex` order. Empty until Phase 11 loads data.
    var columns: [KanbanColumnProjection] = []

    /// `true` while a load or write is in progress.
    var isLoading: Bool = false

    /// Non-nil when the active board is online but unavailable.
    /// Mutually exclusive with `errorMessage`.
    var onlineUnavailable: OnlineBoardUnavailableReason? = nil

    /// Non-nil when a local persistence operation produced an error.
    var errorMessage: String? = nil
}
