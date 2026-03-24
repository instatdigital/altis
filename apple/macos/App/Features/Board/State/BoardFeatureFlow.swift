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

    private let offlineWorker: any OfflineBoardDataWorker
    private let onlineGateway: OnlineBoardGatewayContract
    private let store: OfflineLocalStore
    private let workspaceId: WorkspaceID

    init(
        offlineWorker: any OfflineBoardDataWorker,
        onlineGateway: OnlineBoardGatewayContract,
        store: OfflineLocalStore,
        workspaceId: WorkspaceID
    ) {
        self.offlineWorker = offlineWorker
        self.onlineGateway = onlineGateway
        self.store = store
        self.workspaceId = workspaceId
    }

    // MARK: - Event entry point

    func send(_ event: BoardFeatureEvent) {
        switch event {
        case .appeared(let projectId, let workspaceId):
            // Clear stale state from any previously viewed project before
            // issuing new loads. This prevents the shared flow instance from
            // showing the previous project's rows while the next project's
            // loads are in flight.
            if state.projectId != projectId {
                state.boards = []
                state.offlineErrorMessage = nil
                state.onlineBoardsUnavailable = nil
            }
            state.projectId = projectId
            state.workspaceId = workspaceId
            loadOfflineBoards(projectId: projectId)
            loadOnlineBoards(projectId: projectId)
            loadPresets(workspaceId: workspaceId)

        case .createOfflineBoardRequested(let name, let projectId):
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            guard let wsId = state.workspaceId else { return }
            createOfflineBoard(name: trimmed, projectId: projectId, workspaceId: wsId)

        case .createOfflineBoardFromPresetRequested(let name, let projectId, let presetId):
            let trimmed = name.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return }
            guard let wsId = state.workspaceId else { return }
            createOfflineBoardFromPreset(name: trimmed, projectId: projectId, workspaceId: wsId, presetId: presetId)

        case .boardSelected:
            // Navigation handled by the page/shell layer.
            break

        case .errorAcknowledged:
            state.errorMessage = nil

        case .offlineBoardsLoaded(let projections):
            // Replace offline portion; online items stay in place once loaded.
            let onlineItems = state.boards.filter { $0.mode == .online }
            state.boards = projections + onlineItems
            state.isLoadingOffline = false

        case .offlineLoadFailed(let error):
            state.isLoadingOffline = false
            state.offlineErrorMessage = error.localizedDescription

        case .boardCreated:
            state.isCreating = false
            // Reload the offline board list after creation.
            if let projectId = state.projectId {
                loadOfflineBoards(projectId: projectId)
            }

        case .boardCreateFailed(let error):
            state.isCreating = false
            state.errorMessage = error.localizedDescription

        case .presetsLoaded(let presets):
            state.availablePresets = presets

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
                let projections = try await offlineWorker.loadBoards(projectId: projectId)
                send(.offlineBoardsLoaded(projections))
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

    private func loadPresets(workspaceId: WorkspaceID) {
        _Concurrency.Task {
            do {
                let presets = try await store.fetchBoardStagePresets(workspaceId: workspaceId)
                send(.presetsLoaded(presets))
            } catch {
                // Preset load failure is non-fatal; the creation sheet can still
                // create blank boards without presets.
            }
        }
    }

    private func createOfflineBoard(name: String, projectId: ProjectID, workspaceId: WorkspaceID) {
        state.isCreating = true
        _Concurrency.Task {
            do {
                let board = try await offlineWorker.createBoard(
                    name: name,
                    projectId: projectId,
                    workspaceId: workspaceId
                )
                send(.boardCreated(board))
            } catch {
                send(.boardCreateFailed(error))
            }
        }
    }

    private func createOfflineBoardFromPreset(
        name: String,
        projectId: ProjectID,
        workspaceId: WorkspaceID,
        presetId: BoardStagePresetID
    ) {
        state.isCreating = true
        _Concurrency.Task {
            do {
                guard let preset = state.availablePresets.first(where: { $0.stagePresetId == presetId }) else {
                    throw OfflineBoardWorkerError.invariantViolation("Preset not found: \(presetId.rawValue)")
                }
                let presetStages = try await store.fetchBoardStagePresetStages(stagePresetId: presetId)
                let board = try await offlineWorker.createBoardFromPreset(
                    name: name,
                    projectId: projectId,
                    workspaceId: workspaceId,
                    preset: preset,
                    presetStages: presetStages
                )
                send(.boardCreated(board))
            } catch {
                send(.boardCreateFailed(error))
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
