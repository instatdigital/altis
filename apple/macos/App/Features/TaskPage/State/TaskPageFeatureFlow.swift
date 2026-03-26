import Foundation
import _Concurrency

/// Feature flow for the Task Detail page and Task Creation.
///
/// Owns `TaskPageFeatureState` and processes `TaskPageFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded and mutations persisted via `OfflineTaskPageDataWorker`.
/// - `online` boards: data loaded via an online gateway — routing point defined here,
///   gateway attached in Phase 14.
@MainActor
final class TaskPageFeatureFlow: ObservableObject {

    @Published private(set) var state = TaskPageFeatureState()

    private let offlineWorker: OfflineTaskPageDataWorker
    private let store: any LocalStoreContract & LocalWritePathContract

    init(
        offlineWorker: OfflineTaskPageDataWorker,
        store: any LocalStoreContract & LocalWritePathContract
    ) {
        self.offlineWorker = offlineWorker
        self.store = store
    }

    // MARK: - Event entry point

    func send(_ event: TaskPageFeatureEvent) {
        switch event {
        case .boardContextLoaded(let boardId, let boardMode):
            state.activeBoardId = boardId
            state.boardMode = boardMode
            loadBoardContext(boardId: boardId)

        case .appeared(let taskId, let boardMode):
            state.boardMode = boardMode
            loadTask(taskId: taskId, boardMode: boardMode)

        case .createTaskRequested(let title, let boardId, let stageId, let workspaceId, let projectId):
            createTask(
                title: title,
                boardId: boardId,
                stageId: stageId,
                workspaceId: workspaceId,
                projectId: projectId
            )

        case .stageMoveRequested(let stageId):
            guard let taskId = state.task?.taskId else { return }
            moveTask(taskId: taskId, toStageId: stageId)

        case .completeRequested:
            guard let taskId = state.task?.taskId else { return }
            completeTask(taskId: taskId)

        case .failRequested:
            guard let taskId = state.task?.taskId else { return }
            failTask(taskId: taskId)

        case .errorAcknowledged:
            state.errorMessage = nil

        case .offlineTaskLoaded(let projection):
            state.task = projection
            state.activeBoardId = projection.boardId
            state.activeProjectId = projection.projectId
            // Sync board stages from the loaded task.
            if !projection.boardStages.isEmpty {
                state.boardStages = projection.boardStages
            }
            state.isLoading = false

        case .taskCreated(let projection):
            state.task = projection
            state.activeBoardId = projection.boardId
            state.activeProjectId = projection.projectId
            if !projection.boardStages.isEmpty {
                state.boardStages = projection.boardStages
            }
            state.isCreating = false
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.isLoading = false
            state.onlineUnavailable = reason

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription

        case .writeFailed(let error):
            state.isCreating = false
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Effects

    private func loadBoardContext(boardId: BoardID) {
        _Concurrency.Task {
            do {
                let stages = try await store.fetchBoardStages(boardId: boardId)
                // Update state with stage context for the create-task sheet.
                if let board = try await store.fetchBoard(id: boardId) {
                    state.activeProjectId = board.projectId
                }
                state.boardStages = stages
            } catch {
                // Non-fatal: stage context failed to load. Create sheet will be disabled.
                state.errorMessage = error.localizedDescription
            }
        }
    }

    private func loadTask(taskId: TaskID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            _Concurrency.Task {
                do {
                    let projection = try await offlineWorker.loadTask(taskId: taskId)
                    send(.offlineTaskLoaded(projection))
                } catch {
                    send(.loadFailed(error))
                }
            }
        case .online:
            send(.onlineUnavailable(.notImplemented))
        }
    }

    private func createTask(
        title: String,
        boardId: BoardID,
        stageId: BoardStageID,
        workspaceId: WorkspaceID,
        projectId: ProjectID
    ) {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        state.isCreating = true

        _Concurrency.Task {
            do {
                let now = Date()
                let task = Task(
                    workspaceId: workspaceId,
                    projectId: projectId,
                    boardId: boardId,
                    stageId: stageId,
                    title: trimmed,
                    createdAt: now,
                    updatedAt: now
                )
                try await store.createTask(task)
                let projection = try await offlineWorker.loadTask(taskId: task.taskId)
                send(.taskCreated(projection))
            } catch {
                send(.writeFailed(error))
            }
        }
    }

    private func moveTask(taskId: TaskID, toStageId: BoardStageID) {
        state.isLoading = true
        _Concurrency.Task {
            do {
                let projection = try await offlineWorker.moveTask(taskId: taskId, toStageId: toStageId)
                send(.offlineTaskLoaded(projection))
            } catch {
                send(.writeFailed(error))
            }
        }
    }

    private func completeTask(taskId: TaskID) {
        state.isLoading = true
        _Concurrency.Task {
            do {
                let projection = try await offlineWorker.completeTask(taskId: taskId)
                send(.offlineTaskLoaded(projection))
            } catch {
                send(.writeFailed(error))
            }
        }
    }

    private func failTask(taskId: TaskID) {
        state.isLoading = true
        _Concurrency.Task {
            do {
                let projection = try await offlineWorker.failTask(taskId: taskId)
                send(.offlineTaskLoaded(projection))
            } catch {
                send(.writeFailed(error))
            }
        }
    }
}
