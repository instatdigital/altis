import Foundation
import _Concurrency

/// Feature flow for the Board list and creation surface.
///
/// A project may contain both offline and online boards. This flow loads both
/// authorities independently and merges their projections into one typed list.
///
/// Offline path:  `OfflineBoardDataWorker` → local SQLite → `offlineBoardsLoaded`
/// Online path:   `OnlineBoardGatewayContract` → backend API → `onlineBoardsLoaded`
///                If the gateway throws, `onlineBoardsFailed` carries the reason.
///
/// `onlineBoardsFailed` is emitted only after the gateway call returns an error —
/// never speculatively. See `docs/ARCHITECTURE.md` flow rules.
@MainActor
final class BoardFeatureFlow: ObservableObject {

    @Published private(set) var state = BoardFeatureState()

    private let offlineWorker: OfflineBoardDataWorker
    private let onlineGateway: OnlineBoardGatewayContract

    init(
        offlineWorker: OfflineBoardDataWorker,
        onlineGateway: OnlineBoardGatewayContract
    ) {
        self.offlineWorker = offlineWorker
        self.onlineGateway = onlineGateway
    }

    // MARK: - Event entry point

    func send(_ event: BoardFeatureEvent) {
        switch event {
        case .appeared(let projectId):
            state.projectId = projectId
            loadOfflineBoards(projectId: projectId)
            loadOnlineBoards(projectId: projectId)

        case .createOfflineBoardRequested:
            // Phase 7 implementation.
            break

        case .createOfflineBoardFromPresetRequested:
            // Phase 7 implementation.
            break

        case .boardSelected:
            // Navigation handled by the page/shell layer.
            break

        case .offlineBoardsLoaded(let boards):
            let offlineItems = boards.map { board in
                BoardListItemProjection(board: board, stageCount: 0, taskCount: 0)
            }
            // Replace offline portion; online items stay in place once loaded.
            let onlineItems = state.boards.filter { $0.mode == .online }
            state.boards = offlineItems + onlineItems
            state.isLoadingOffline = false

        case .offlineLoadFailed(let error):
            state.isLoadingOffline = false
            state.offlineErrorMessage = error.localizedDescription

        case .onlineBoardsLoaded(let models):
            let onlineItems = models.map { BoardListItemProjection(onlineBoard: $0) }
            // Replace online portion; offline items stay in place.
            let offlineItems = state.boards.filter { $0.mode == .offline }
            state.boards = offlineItems + onlineItems
            state.isLoadingOnline = false
            state.onlineBoardsUnavailable = nil

        case .onlineBoardsFailed(let reason):
            state.isLoadingOnline = false
            state.onlineBoardsUnavailable = reason
        }
    }

    // MARK: - Effects

    private func loadOfflineBoards(projectId: ProjectID) {
        state.isLoadingOffline = true
        _Concurrency.Task {
            do {
                let boards = try await offlineWorker.loadBoards(projectId: projectId)
                send(.offlineBoardsLoaded(boards))
            } catch {
                send(.offlineLoadFailed(error))
            }
        }
    }

    private func loadOnlineBoards(projectId: ProjectID) {
        state.isLoadingOnline = true
        _Concurrency.Task {
            do {
                let models = try await onlineGateway.fetchBoards(projectId: projectId)
                send(.onlineBoardsLoaded(models))
            } catch {
                // Gateway threw — the online path was attempted and is currently unusable.
                // Map the concrete error to a typed reason so the UI surfaces the correct message.
                send(.onlineBoardsFailed(unavailableReason(for: error)))
            }
        }
    }

    // MARK: - Error mapping

    /// Maps a gateway error to the most specific `OnlineBoardUnavailableReason`.
    ///
    /// Auth-specific codes are checked first so they are not swallowed by the
    /// broad `NSURLErrorDomain` fallback. Remaining network-layer errors then
    /// surface `networkUnavailable`. All other errors default to `networkUnavailable`
    /// until richer error types are introduced in Phase 14.
    private func unavailableReason(for error: Error) -> OnlineBoardUnavailableReason {
        let nsError = error as NSError
        // Check auth-specific URL error codes before the broad domain fallback,
        // so authentication failures are not misclassified as connectivity loss.
        let authErrorCodes: Set<Int> = [
            NSURLErrorUserAuthenticationRequired,
            NSURLErrorUserCancelledAuthentication
        ]
        if nsError.domain == NSURLErrorDomain && authErrorCodes.contains(nsError.code) {
            return .notAuthenticated
        }
        // Remaining URLSession / network-layer errors signal connectivity loss.
        if nsError.domain == NSURLErrorDomain {
            return .networkUnavailable
        }
        // Default to network unavailable; further specialisation deferred to Phase 14.
        return .networkUnavailable
    }
}
