import Foundation

struct PermissiveOnlineBoardAuthGate: OnlineBoardAuthGateContract {
    func requireAccess() async throws {}
}

/// Phase-14 placeholder conformance for `OnlineBoardGatewayContract`.
///
/// Throws a typed network-unavailable error for every call so the online path
/// stays explicit without falling back to local durable writes.
struct NotImplementedOnlineBoardGateway: OnlineBoardGatewayContract {
    func fetchBoards(projectId: ProjectID) async throws -> [OnlineBoardReadModel] {
        throw OnlineBoardAccessError.networkUnavailable
    }
    func fetchBoardContent(boardId: BoardID) async throws -> OnlineBoardContentReadModel {
        throw OnlineBoardAccessError.networkUnavailable
    }
    func fetchTask(taskId: TaskID) async throws -> OnlineTaskReadModel {
        throw OnlineBoardAccessError.networkUnavailable
    }
    func moveTask(_ request: OnlineTaskStageMoveWriteModel) async throws -> OnlineTaskReadModel {
        throw OnlineBoardAccessError.networkUnavailable
    }
    func applyTerminalAction(_ request: OnlineTaskTerminalActionWriteModel) async throws -> OnlineTaskReadModel {
        throw OnlineBoardAccessError.networkUnavailable
    }
}

/// Shared application-level dependencies injected into the view hierarchy.
///
/// `AppEnvironment` owns the single `OfflineLocalStore` instance and the
/// default workspace identifier used for all local offline entities.
///
/// Phase 6: project store and workspace identity.
/// Phase 7: board store and board creation worker.
/// Later phases will extend this struct when task and other stores are needed.
struct AppEnvironment {

    /// The single SQLite-backed offline store shared across all feature flows.
    let store: OfflineLocalStore

    /// Default local workspace identifier.
    ///
    /// In the current offline-only phase the app operates within one implicit
    /// local workspace. The identifier is generated once per install and
    /// persisted in `UserDefaults` so it remains stable across restarts.
    let workspaceId: WorkspaceID

    let onlineBoardAuthGate: OnlineBoardAuthGateContract
    let onlineBoardGateway: OnlineBoardGatewayContract

    // MARK: - Factory

    /// Creates the production environment, opening (or creating) the SQLite
    /// database at the default application-support path.
    static func production() async throws -> AppEnvironment {
        let store = try await OfflineLocalStore()
        let workspaceId = resolvedWorkspaceId()
        return AppEnvironment(
            store: store,
            workspaceId: workspaceId,
            onlineBoardAuthGate: PermissiveOnlineBoardAuthGate(),
            onlineBoardGateway: NotImplementedOnlineBoardGateway()
        )
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
