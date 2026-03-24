import Foundation

/// Shared application-level dependencies injected into the view hierarchy.
///
/// `AppEnvironment` owns the single `OfflineLocalStore` instance and the
/// default workspace identifier used for all local offline entities.
///
/// Phase 6: project store and workspace identity.
/// Later phases will extend this struct when board, task, and other stores are needed.
struct AppEnvironment {

    /// The single SQLite-backed offline store shared across all feature flows.
    let store: OfflineLocalStore

    /// Default local workspace identifier.
    ///
    /// In the current offline-only phase the app operates within one implicit
    /// local workspace. The identifier is generated once per install and
    /// persisted in `UserDefaults` so it remains stable across restarts.
    let workspaceId: WorkspaceID

    // MARK: - Factory

    /// Creates the production environment, opening (or creating) the SQLite
    /// database at the default application-support path.
    static func production() async throws -> AppEnvironment {
        let store = try await OfflineLocalStore()
        let workspaceId = resolvedWorkspaceId()
        return AppEnvironment(store: store, workspaceId: workspaceId)
    }

    // MARK: - Workspace identity

    private static let workspaceIdKey = "altis.localWorkspaceId"

    private static func resolvedWorkspaceId() -> WorkspaceID {
        if let stored = UserDefaults.standard.string(forKey: workspaceIdKey) {
            return WorkspaceID(rawValue: stored)
        }
        let new = WorkspaceID()
        UserDefaults.standard.set(new.rawValue, forKey: workspaceIdKey)
        return new
    }
}
