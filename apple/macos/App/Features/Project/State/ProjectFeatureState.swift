import Foundation

/// Render state owned by `ProjectFeatureFlow`.
struct ProjectFeatureState {

    /// Typed projections shown in the project list. Empty until Phase 6 loads data.
    var projects: [ProjectListItemProjection] = []

    /// `true` while a load or save is in progress.
    var isLoading: Bool = false

    /// Non-nil when the last persistence operation produced an error.
    var errorMessage: String? = nil
}
