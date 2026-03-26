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
///
/// All background tasks are tracked in `activeTasks`. When the viewed project
/// changes, `cancelActiveTasks()` cancels every in-flight load or mutation so
/// that stale async work cannot call into the SQLite store after the connection
/// is closed or the flow is torn down.
@MainActor
final class BoardFeatureFlow: ObservableObject {

    @Published private(set) var state = BoardFeatureState()

    private let offlineWorker: any OfflineBoardDataWorker
    private let onlineGateway: OnlineBoardGatewayContract
    private let store: any LocalStoreContract
    private let workspaceId: WorkspaceID

    /// All in-flight background tasks. Stored so they can be cancelled on
    /// project switch or flow teardown, preventing calls into a closed store.
    private var activeTasks: [_Concurrency.Task<Void, Never>] = []

    init(
        offlineWorker: any OfflineBoardDataWorker,
        onlineGateway: OnlineBoardGatewayContract,
        store: any LocalStoreContract,
        workspaceId: WorkspaceID
    ) {
        self.offlineWorker = offlineWorker
        self.onlineGateway = onlineGateway
        self.store = store
        self.workspaceId = workspaceId
    }

    deinit {
        for task in activeTasks { task.cancel() }
    }

    // MARK: - Event entry point

    func send(_ event: BoardFeatureEvent) {
        switch event {
        case .appeared(let projectId, let workspaceId):
            // Cancel any in-flight tasks for the previous project before
            // issuing new loads. This prevents stale async work from calling
            // into the store after the connection is closed or after the
            // project context has changed.
            if state.projectId != projectId {
                cancelActiveTasks()
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

        case .stageEditorRequested(let board):
            guard board.mode == .offline else { return }
            state.stageEditorBoard = board
            state.boardStages = []
            state.isLoadingStages = true
            loadStages(boardId: board.boardId)

        case .stageEditorDismissed:
            state.stageEditorBoard = nil
            state.boardStages = []
            state.isLoadingStages = false
            state.isMutatingStages = false

        case .addStageRequested(let boardId, let name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            mutateStages {
                try await self.offlineWorker.addStage(boardId: boardId, name: trimmed)
            }

        case .renameStageRequested(let boardId, let stageId, let name):
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { return }
            mutateStages {
                try await self.offlineWorker.renameStage(boardId: boardId, stageId: stageId, name: trimmed)
            }

        case .deleteStageRequested(let boardId, let stageId):
            mutateStages {
                try await self.offlineWorker.deleteStage(boardId: boardId, stageId: stageId)
            }

        case .moveStageRequested(let boardId, let stageId, let destinationIndex):
            mutateStages {
                try await self.offlineWorker.moveStage(boardId: boardId, stageId: stageId, to: destinationIndex)
            }

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

        case .boardStagesLoaded(let boardId, let stages):
            if state.stageEditorBoard?.boardId == boardId {
                state.boardStages = stages
            }
            state.isLoadingStages = false
            applyStageCount(stages.count, to: boardId)

        case .boardStagesLoadFailed(let error):
            state.isLoadingStages = false
            state.errorMessage = error.localizedDescription

        case .boardStagesUpdated(let boardId, let stages):
            if state.stageEditorBoard?.boardId == boardId {
                state.boardStages = stages
            }
            state.isMutatingStages = false
            applyStageCount(stages.count, to: boardId)

        case .boardStageMutationFailed(let error):
            state.isMutatingStages = false
            state.errorMessage = error.localizedDescription

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

    // MARK: - Task lifecycle

    /// Cancels all in-flight background tasks and removes them from the
    /// tracking list. Called on project switch so stale async work cannot
    /// call into the store after the project context has changed.
    ///
    /// This is synchronous — it signals cancellation but does not wait for
    /// tasks to finish. Use `cancelAndDrainActiveTasks()` when you need to
    /// ensure all tasks have fully stopped before proceeding (e.g. closing
    /// the store in tests).
    func cancelActiveTasks() {
        for task in activeTasks { task.cancel() }
        activeTasks.removeAll()
    }

    /// Cancels all in-flight background tasks and waits for each to finish
    /// before returning. Use this before closing the underlying store so that
    /// no task can call SQLite on a closed connection.
    func cancelAndDrainActiveTasks() async {
        let snapshot = activeTasks
        activeTasks.removeAll()
        for task in snapshot {
            task.cancel()
            _ = await task.result
        }
    }

    /// Spawns a `@MainActor`-isolated background task (inheriting the flow's
    /// actor isolation), tracks it in `activeTasks` so it can be cancelled,
    /// and removes it from the list when it finishes so the array only holds
    /// genuinely in-flight work.
    @discardableResult
    private func spawnTask(_ body: @escaping () async -> Void) -> _Concurrency.Task<Void, Never> {
        // Append a sentinel index so we can splice the finished task out by
        // appending it, running the body, then removing by identity.
        // `Task<Void, Never>` is `Equatable` so identity comparison is safe.
        let task = _Concurrency.Task {
            await body()
        }
        activeTasks.append(task)
        // Schedule a cleanup task that waits for the work task to finish and
        // then removes it. The cleanup task itself is NOT tracked so it does
        // not prevent cancellation of the work task.
        _Concurrency.Task {
            _ = await task.result
            self.activeTasks.removeAll(where: { $0 == task })
        }
        return task
    }

    // MARK: - Effects

    private func loadOfflineBoards(projectId: ProjectID) {
        state.isLoadingOffline = true
        spawnTask {
            do {
                let projections = try await self.offlineWorker.loadBoards(projectId: projectId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.offlineBoardsLoaded(projections))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.offlineLoadFailed(error))
            }
        }
    }

    private func loadOnlineBoards(projectId: ProjectID) {
        state.isLoadingOnline = true
        spawnTask {
            do {
                let models = try await self.onlineGateway.fetchBoards(projectId: projectId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.onlineBoardsLoaded(models))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                // Gateway threw — the online path was attempted and is currently unusable.
                // Map the concrete error to a typed reason so the UI surfaces the correct message.
                self.send(.onlineBoardsFailed(self.unavailableReason(for: error)))
            }
        }
    }

    private func loadPresets(workspaceId: WorkspaceID) {
        spawnTask {
            do {
                let presets = try await self.store.fetchBoardStagePresets(workspaceId: workspaceId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.presetsLoaded(presets))
            } catch {
                // Preset load failure is non-fatal; the creation sheet can still
                // create blank boards without presets.
            }
        }
    }

    private func createOfflineBoard(name: String, projectId: ProjectID, workspaceId: WorkspaceID) {
        state.isCreating = true
        spawnTask {
            do {
                let board = try await self.offlineWorker.createBoard(
                    name: name,
                    projectId: projectId,
                    workspaceId: workspaceId
                )
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardCreated(board))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardCreateFailed(error))
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
        spawnTask {
            do {
                guard let preset = self.state.availablePresets.first(where: { $0.stagePresetId == presetId }) else {
                    throw OfflineBoardWorkerError.invariantViolation("Preset not found: \(presetId.rawValue)")
                }
                let presetStages = try await self.store.fetchBoardStagePresetStages(stagePresetId: presetId)
                guard !_Concurrency.Task.isCancelled else { return }
                let board = try await self.offlineWorker.createBoardFromPreset(
                    name: name,
                    projectId: projectId,
                    workspaceId: workspaceId,
                    preset: preset,
                    presetStages: presetStages
                )
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardCreated(board))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardCreateFailed(error))
            }
        }
    }

    private func loadStages(boardId: BoardID) {
        spawnTask {
            do {
                let stages = try await self.offlineWorker.loadStages(boardId: boardId)
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardStagesLoaded(boardId: boardId, stages: stages))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardStagesLoadFailed(error))
            }
        }
    }

    private func mutateStages(
        operation: @escaping @Sendable () async throws -> [BoardStage]
    ) {
        guard let boardId = state.stageEditorBoard?.boardId else { return }
        state.isMutatingStages = true
        spawnTask {
            do {
                let stages = try await operation()
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardStagesUpdated(boardId: boardId, stages: stages))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.boardStageMutationFailed(error))
            }
        }
    }

    private func applyStageCount(_ count: Int, to boardId: BoardID) {
        state.boards = state.boards.map { board in
            guard board.boardId == boardId else { return board }
            return BoardListItemProjection(
                boardId: board.boardId,
                projectId: board.projectId,
                name: board.name,
                mode: board.mode,
                stageCount: count,
                taskCount: board.taskCount
            )
        }
        if let editorBoard = state.stageEditorBoard, editorBoard.boardId == boardId {
            state.stageEditorBoard = BoardListItemProjection(
                boardId: editorBoard.boardId,
                projectId: editorBoard.projectId,
                name: editorBoard.name,
                mode: editorBoard.mode,
                stageCount: count,
                taskCount: editorBoard.taskCount
            )
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
