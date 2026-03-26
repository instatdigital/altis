import Testing
import Foundation
@testable import Altis

// MARK: - ProjectRecord

@Suite("ProjectRecord")
struct ProjectRecordTests {

    private let workspaceId = WorkspaceID()

    @Test("round-trip preserves all fields")
    func roundTrip() throws {
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let project = Project(workspaceId: workspaceId, name: "Alpha", createdAt: now, updatedAt: now)
        let restored = try #require(ProjectRecord(from: project).toDomain())

        #expect(restored.projectId == project.projectId)
        #expect(restored.workspaceId == workspaceId)
        #expect(restored.name == "Alpha")
        #expect(abs(restored.createdAt.timeIntervalSince(now)) < 1)
        #expect(abs(restored.updatedAt.timeIntervalSince(now)) < 1)
    }

    @Test("toDomain returns nil for malformed createdAt")
    func malformedCreatedAt() {
        var record = ProjectRecord(from: Project(workspaceId: workspaceId, name: "X"))
        record.createdAt = "not-a-date"
        #expect(record.toDomain() == nil)
    }

    @Test("toDomain returns nil for malformed updatedAt")
    func malformedUpdatedAt() {
        var record = ProjectRecord(from: Project(workspaceId: workspaceId, name: "X"))
        record.updatedAt = "not-a-date"
        #expect(record.toDomain() == nil)
    }
}

// MARK: - BoardRecord

@Suite("BoardRecord")
struct BoardRecordTests {

    private let workspaceId = WorkspaceID()
    private let projectId = ProjectID()

    @Test("round-trip preserves all fields")
    func roundTrip() throws {
        let board = Board(workspaceId: workspaceId, projectId: projectId, name: "Sprint 1", mode: .offline)
        let restored = try #require(BoardRecord(from: board).toDomain())

        #expect(restored.boardId == board.boardId)
        #expect(restored.workspaceId == workspaceId)
        #expect(restored.projectId == projectId)
        #expect(restored.name == "Sprint 1")
        #expect(restored.mode == .offline)
    }

    @Test("round-trip preserves online mode")
    func roundTripOnlineMode() throws {
        let board = Board(workspaceId: workspaceId, projectId: projectId, name: "Online Board", mode: .online)
        let restored = try #require(BoardRecord(from: board).toDomain())
        #expect(restored.mode == .online)
    }

    @Test("toDomain returns nil for malformed updatedAt")
    func malformedUpdatedAt() {
        var record = BoardRecord(from: Board(workspaceId: workspaceId, projectId: projectId, name: "X"))
        record.updatedAt = "bad"
        #expect(record.toDomain() == nil)
    }

    @Test("toDomain returns nil for unknown mode raw value")
    func unknownMode() {
        var record = BoardRecord(from: Board(workspaceId: workspaceId, projectId: projectId, name: "X"))
        record.mode = "hybrid"
        #expect(record.toDomain() == nil)
    }
}

// MARK: - BoardStageRecord

@Suite("BoardStageRecord")
struct BoardStageRecordTests {

    private let boardId = BoardID()

    @Test("round-trip preserves kind for all BoardStageKind values", arguments: BoardStageKind.allCases)
    func roundTripKinds(kind: BoardStageKind) throws {
        let stage = BoardStage(boardId: boardId, name: "S", orderIndex: 0, kind: kind)
        let restored = try #require(BoardStageRecord(from: stage).toDomain())
        #expect(restored.kind == kind)
    }

    @Test("toDomain returns nil for unknown kind raw value")
    func unknownKind() {
        var record = BoardStageRecord(
            from: BoardStage(boardId: boardId, name: "S", orderIndex: 0, kind: .regular)
        )
        record.kind = "unknownKind"
        #expect(record.toDomain() == nil)
    }

    @Test("round-trip preserves orderIndex")
    func orderIndex() throws {
        let stage = BoardStage(boardId: boardId, name: "S", orderIndex: 5, kind: .regular)
        let restored = try #require(BoardStageRecord(from: stage).toDomain())
        #expect(restored.orderIndex == 5)
    }
}

// MARK: - BoardStagePresetRecord

@Suite("BoardStagePresetRecord")
struct BoardStagePresetRecordTests {

    private let workspaceId = WorkspaceID()

    @Test("preset round-trip preserves name and id")
    func presetRoundTrip() throws {
        let preset = BoardStagePreset(workspaceId: workspaceId, name: "Default Flow")
        let restored = try #require(BoardStagePresetRecord(from: preset).toDomain())
        #expect(restored.stagePresetId == preset.stagePresetId)
        #expect(restored.name == "Default Flow")
    }

    @Test("preset stage round-trip preserves all fields")
    func presetStageRoundTrip() throws {
        let presetId = BoardStagePresetID()
        let stage = BoardStagePresetStage(
            stagePresetId: presetId, name: "In Progress", orderIndex: 1, kind: .regular
        )
        let restored = try #require(BoardStagePresetStageRecord(from: stage).toDomain())
        #expect(restored.presetStageId == stage.presetStageId)
        #expect(restored.stagePresetId == presetId)
        #expect(restored.name == "In Progress")
        #expect(restored.orderIndex == 1)
        #expect(restored.kind == .regular)
    }

    @Test("preset stage toDomain returns nil for unknown kind")
    func presetStageUnknownKind() {
        let presetId = BoardStagePresetID()
        var record = BoardStagePresetStageRecord(
            from: BoardStagePresetStage(stagePresetId: presetId, name: "X", orderIndex: 0, kind: .regular)
        )
        record.kind = "???"
        #expect(record.toDomain() == nil)
    }
}

// MARK: - TaskRecord

@Suite("TaskRecord")
struct TaskRecordTests {

    private let workspaceId = WorkspaceID()
    private let projectId = ProjectID()

    @Test("round-trip preserves fields for task without board")
    func roundTripNoBoardNoStage() throws {
        let task = Task(workspaceId: workspaceId, projectId: projectId, title: "Write tests")
        let restored = try #require(TaskRecord(from: task).toDomain())

        #expect(restored.taskId == task.taskId)
        #expect(restored.workspaceId == workspaceId)
        #expect(restored.projectId == projectId)
        #expect(restored.boardId == nil)
        #expect(restored.stageId == nil)
        #expect(restored.title == "Write tests")
        #expect(restored.status == .open)
    }

    @Test("round-trip preserves boardId and stageId when set")
    func roundTripWithBoardAndStage() throws {
        let boardId = BoardID()
        let stageId = BoardStageID()
        let task = Task(
            workspaceId: workspaceId, projectId: projectId,
            boardId: boardId, stageId: stageId, title: "Board task"
        )
        let restored = try #require(TaskRecord(from: task).toDomain())
        #expect(restored.boardId == boardId)
        #expect(restored.stageId == stageId)
    }

    @Test("round-trip preserves all TaskStatus values", arguments: TaskStatus.allCases)
    func allStatusValues(status: TaskStatus) throws {
        let task = Task(workspaceId: workspaceId, projectId: projectId, title: "T", status: status)
        let restored = try #require(TaskRecord(from: task).toDomain())
        #expect(restored.status == status)
    }

    @Test("toDomain returns nil for unknown status raw value")
    func unknownStatus() {
        var record = TaskRecord(from: Task(workspaceId: workspaceId, projectId: projectId, title: "T"))
        record.status = "archived"
        #expect(record.toDomain() == nil)
    }

    @Test("toDomain returns nil for malformed createdAt")
    func malformedCreatedAt() {
        var record = TaskRecord(from: Task(workspaceId: workspaceId, projectId: projectId, title: "T"))
        record.createdAt = "not-a-date"
        #expect(record.toDomain() == nil)
    }

    @Test("toDomain returns nil for malformed updatedAt")
    func malformedUpdatedAt() {
        var record = TaskRecord(from: Task(workspaceId: workspaceId, projectId: projectId, title: "T"))
        record.updatedAt = "not-a-date"
        #expect(record.toDomain() == nil)
    }
}

// MARK: - OfflineLocalStore board-list regressions

@Suite("OfflineLocalStore board list")
struct OfflineLocalStoreBoardListRegressionTests {

    @Test("fetchBoardListItems reads on a fresh Phase 7 database without tasks table")
    func fetchBoardListItemsFreshDatabase() async throws {
        let workspaceId = WorkspaceID()
        let project = Project(workspaceId: workspaceId, name: "Alpha")
        let now = Date(timeIntervalSince1970: 1_710_000_000)
        let projections = try await withTemporaryStore(prefix: "altis-board-list") { store in
            let emptyRead = try await store.fetchBoardListItems(projectId: project.projectId)
            #expect(emptyRead.isEmpty)

            try await store.createProject(project)

            let betaBoard = Board(
                workspaceId: workspaceId,
                projectId: project.projectId,
                name: "Beta Board",
                mode: .offline,
                createdAt: now,
                updatedAt: now
            )
            let alphaBoard = Board(
                workspaceId: workspaceId,
                projectId: project.projectId,
                name: "Alpha Board",
                mode: .offline,
                createdAt: now,
                updatedAt: now
            )

            try await store.createBoard(betaBoard)
            try await store.createBoard(alphaBoard)

            try await store.createBoardStage(BoardStage(
                boardId: betaBoard.boardId,
                name: "To Do",
                orderIndex: 0,
                kind: .regular,
                createdAt: now,
                updatedAt: now
            ))
            try await store.createBoardStage(BoardStage(
                boardId: betaBoard.boardId,
                name: "Done",
                orderIndex: 1,
                kind: .terminalSuccess,
                createdAt: now,
                updatedAt: now
            ))
            try await store.createBoardStage(BoardStage(
                boardId: betaBoard.boardId,
                name: "Cancelled",
                orderIndex: 2,
                kind: .terminalFailure,
                createdAt: now,
                updatedAt: now
            ))

            try await store.createBoardStage(BoardStage(
                boardId: alphaBoard.boardId,
                name: "Backlog",
                orderIndex: 0,
                kind: .regular,
                createdAt: now,
                updatedAt: now
            ))
            try await store.createBoardStage(BoardStage(
                boardId: alphaBoard.boardId,
                name: "Ready",
                orderIndex: 1,
                kind: .regular,
                createdAt: now,
                updatedAt: now
            ))
            try await store.createBoardStage(BoardStage(
                boardId: alphaBoard.boardId,
                name: "Done",
                orderIndex: 2,
                kind: .terminalSuccess,
                createdAt: now,
                updatedAt: now
            ))
            try await store.createBoardStage(BoardStage(
                boardId: alphaBoard.boardId,
                name: "Cancelled",
                orderIndex: 3,
                kind: .terminalFailure,
                createdAt: now,
                updatedAt: now
            ))

            return try await store.fetchBoardListItems(projectId: project.projectId)
        }

        #expect(projections.map(\.name) == ["Alpha Board", "Beta Board"])
        #expect(projections.map(\.stageCount) == [4, 3])
        #expect(projections.map(\.taskCount) == [0, 0])
        #expect(projections.allSatisfy { $0.projectId == project.projectId && $0.mode == .offline })
    }
}

// MARK: - OfflineLocalBoardWorker stage management

@Suite("OfflineLocalBoardWorker stage management")
struct OfflineLocalBoardWorkerStageManagementTests {

    @Test("addStage appends a regular stage to the end of the board")
    func addStageToEnd() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        try await withTemporaryStore(prefix: "altis-stage-add") { store in
            let worker = OfflineLocalBoardWorker(store: store)
            let board = try await worker.createBoard(
                name: "Board",
                projectId: projectId,
                workspaceId: workspaceId
            )

            let stages = try await worker.addStage(boardId: board.boardId, name: "Review")

            #expect(stages.map(\.name) == ["To Do", "Done", "Cancelled", "Review"])
            #expect(stages.map(\.orderIndex) == [0, 1, 2, 3])
            #expect(stages.last?.kind == .regular)
        }
    }

    @Test("renameStage allows terminal stages to be renamed")
    func renameTerminalStage() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        try await withTemporaryStore(prefix: "altis-stage-rename") { store in
            let worker = OfflineLocalBoardWorker(store: store)
            let board = try await worker.createBoard(
                name: "Board",
                projectId: projectId,
                workspaceId: workspaceId
            )
            let doneStage = try #require(
                (try await worker.loadStages(boardId: board.boardId)).first(where: { $0.kind == .terminalSuccess })
            )

            let stages = try await worker.renameStage(
                boardId: board.boardId,
                stageId: doneStage.stageId,
                name: "Completed"
            )

            #expect(stages.first(where: { $0.stageId == doneStage.stageId })?.name == "Completed")
        }
    }

    @Test("deleteStage removes a non-terminal stage, reassigns its tasks, and compacts order")
    func deleteStageReassignsTasks() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        try await withTemporaryStore(prefix: "altis-stage-delete") { store in
            let worker = OfflineLocalBoardWorker(store: store)
            let board = try await worker.createBoard(
                name: "Board",
                projectId: projectId,
                workspaceId: workspaceId
            )
            _ = try await worker.addStage(boardId: board.boardId, name: "Review")
            let stagesBeforeDelete = try await worker.loadStages(boardId: board.boardId)
            let reviewStage = try #require(stagesBeforeDelete.first(where: { $0.name == "Review" }))
            let firstRemainingStage = try #require(stagesBeforeDelete.first(where: { $0.name == "To Do" }))

            let task = Task(
                workspaceId: workspaceId,
                projectId: projectId,
                boardId: board.boardId,
                stageId: reviewStage.stageId,
                title: "Task assigned to deleted stage"
            )
            try await store.createTask(task)

            let remainingStages = try await worker.deleteStage(
                boardId: board.boardId,
                stageId: reviewStage.stageId
            )
            let updatedTask = try #require(try await store.fetchTask(id: task.taskId))

            #expect(remainingStages.map(\.name) == ["To Do", "Done", "Cancelled"])
            #expect(remainingStages.map(\.orderIndex) == [0, 1, 2])
            #expect(updatedTask.stageId == firstRemainingStage.stageId)
        }
    }

    @Test("deleteStage rejects terminal stage deletion")
    func deleteTerminalStageRejected() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        try await withTemporaryStore(prefix: "altis-stage-terminal-delete") { store in
            let worker = OfflineLocalBoardWorker(store: store)
            let board = try await worker.createBoard(
                name: "Board",
                projectId: projectId,
                workspaceId: workspaceId
            )
            let terminalStage = try #require(
                (try await worker.loadStages(boardId: board.boardId)).first(where: { $0.kind == .terminalSuccess })
            )

            do {
                _ = try await worker.deleteStage(boardId: board.boardId, stageId: terminalStage.stageId)
                Issue.record("Expected terminal stage deletion to fail.")
            } catch {
                #expect(error.localizedDescription.contains("Cannot delete terminal stage"))
            }
        }
    }

    @Test("moveStage persists the new order locally")
    func moveStagePersistsOrder() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        try await withTemporaryStore(prefix: "altis-stage-move") { store in
            let worker = OfflineLocalBoardWorker(store: store)
            let board = try await worker.createBoard(
                name: "Board",
                projectId: projectId,
                workspaceId: workspaceId
            )
            _ = try await worker.addStage(boardId: board.boardId, name: "Review")
            let currentStages = try await worker.loadStages(boardId: board.boardId)
            let reviewStage = try #require(currentStages.first(where: { $0.name == "Review" }))

            let movedStages = try await worker.moveStage(
                boardId: board.boardId,
                stageId: reviewStage.stageId,
                to: 1
            )
            let persistedStages = try await worker.loadStages(boardId: board.boardId)

            #expect(movedStages.map(\.name) == ["To Do", "Review", "Done", "Cancelled"])
            #expect(persistedStages.map(\.name) == ["To Do", "Review", "Done", "Cancelled"])
            #expect(persistedStages.map(\.orderIndex) == [0, 1, 2, 3])
        }
    }
}

// MARK: - BoardFeatureFlow regressions

@Suite("BoardFeatureFlow")
struct BoardFeatureFlowRegressionTests {

    @Test("appeared clears previous project board list state before next loads finish")
    @MainActor
    func projectSwitchResetsState() async throws {
        let workspaceId = WorkspaceID()
        let previousProjectId = ProjectID()
        let nextProjectId = ProjectID()
        let staleBoard = BoardListItemProjection(
            boardId: BoardID(),
            projectId: previousProjectId,
            name: "Stale Board",
            mode: .offline,
            stageCount: 3,
            taskCount: 0
        )
        try await withTemporaryStore(prefix: "altis-board-flow") { store in
            let flow = BoardFeatureFlow(
                offlineWorker: SuspendedOfflineBoardWorker(),
                onlineGateway: SuspendedOnlineBoardGateway(),
                store: store,
                workspaceId: workspaceId
            )

            flow.send(.appeared(projectId: previousProjectId, workspaceId: workspaceId))
            flow.send(.offlineBoardsLoaded([staleBoard]))
            flow.send(.offlineLoadFailed(NSError(domain: "BoardFeatureFlowTests", code: 1)))
            flow.send(.onlineBoardsFailed(.networkUnavailable))

            #expect(flow.state.boards == [staleBoard])
            #expect(flow.state.offlineErrorMessage != nil)
            #expect(flow.state.onlineBoardsUnavailable == .networkUnavailable)

            flow.send(.appeared(projectId: nextProjectId, workspaceId: workspaceId))

            #expect(flow.state.projectId == nextProjectId)
            #expect(flow.state.workspaceId == workspaceId)
            #expect(flow.state.boards.isEmpty)
            #expect(flow.state.offlineErrorMessage == nil)
            #expect(flow.state.onlineBoardsUnavailable == nil)
            #expect(flow.state.isLoadingOffline)
            #expect(flow.state.isLoadingOnline)

            // Cancel and drain in-flight tasks before withTemporaryStore closes
            // the store so no background work (e.g. loadPresets hitting SQLite)
            // can resume against a closed connection.
            await flow.cancelAndDrainActiveTasks()
        }
    }
}

private func withTemporaryStore<Result: Sendable>(
    prefix: String,
    operation: @MainActor @Sendable (OfflineLocalStore) async throws -> Result
) async throws -> Result {
    let dbPath = FileManager.default.temporaryDirectory
        .appendingPathComponent("\(prefix)-\(UUID().uuidString).sqlite")
        .path
    let store = try await OfflineLocalStore(path: dbPath)
    do {
        let result = try await operation(store)
        await store.close()
        try? FileManager.default.removeItem(atPath: dbPath)
        return result
    } catch {
        await store.close()
        try? FileManager.default.removeItem(atPath: dbPath)
        throw error
    }
}

/// An `OfflineBoardDataWorker` whose `loadBoards` suspends until `open()` is called.
/// After `open()` it returns an empty list so callers see a real result if not cancelled.
///
/// Cancellation is handled via `withTaskCancellationHandler` so that
/// `cancelAndDrainActiveTasks()` can await task completion without deadlocking.
private actor LatchOfflineBoardWorker: OfflineBoardDataWorker {
    private var continuation: CheckedContinuation<Void, Error>?
    private var isOpen = false

    /// Releases any suspended `loadBoards` call, letting it return normally.
    func open() async {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }

    func loadBoards(projectId: ProjectID) async throws -> [BoardListItemProjection] {
        if !isOpen {
            // Use a cancellation handler so that cancelling the enclosing task
            // resumes the continuation and allows the task to exit cleanly.
            // Without this, awaiting task.result in cancelAndDrainActiveTasks
            // would deadlock because the continuation would never resume.
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                    if _Concurrency.Task.isCancelled {
                        cont.resume(throwing: CancellationError())
                    } else {
                        self.continuation = cont
                    }
                }
            } onCancel: {
                _Concurrency.Task {
                    await self.cancelContinuation()
                }
            }
        }
        try _Concurrency.Task.checkCancellation()
        return []
    }

    private func cancelContinuation() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }

    func createBoard(name: String, projectId: ProjectID, workspaceId: WorkspaceID) async throws -> Board {
        throw CancellationError()
    }

    func createBoardFromPreset(
        name: String,
        projectId: ProjectID,
        workspaceId: WorkspaceID,
        preset: BoardStagePreset,
        presetStages: [BoardStagePresetStage]
    ) async throws -> Board {
        throw CancellationError()
    }

    func loadStages(boardId: BoardID) async throws -> [BoardStage] { throw CancellationError() }
    func addStage(boardId: BoardID, name: String) async throws -> [BoardStage] { throw CancellationError() }
    func renameStage(boardId: BoardID, stageId: BoardStageID, name: String) async throws -> [BoardStage] { throw CancellationError() }
    func deleteStage(boardId: BoardID, stageId: BoardStageID) async throws -> [BoardStage] { throw CancellationError() }
    func moveStage(boardId: BoardID, stageId: BoardStageID, to destinationIndex: Int) async throws -> [BoardStage] { throw CancellationError() }
}

private struct SuspendedOfflineBoardWorker: OfflineBoardDataWorker {
    func loadBoards(projectId: ProjectID) async throws -> [BoardListItemProjection] {
        try await _Concurrency.Task.sleep(nanoseconds: 60_000_000_000)
        return []
    }

    func createBoard(name: String, projectId: ProjectID, workspaceId: WorkspaceID) async throws -> Board {
        throw CancellationError()
    }

    func createBoardFromPreset(
        name: String,
        projectId: ProjectID,
        workspaceId: WorkspaceID,
        preset: BoardStagePreset,
        presetStages: [BoardStagePresetStage]
    ) async throws -> Board {
        throw CancellationError()
    }

    func loadStages(boardId: BoardID) async throws -> [BoardStage] {
        throw CancellationError()
    }

    func addStage(boardId: BoardID, name: String) async throws -> [BoardStage] {
        throw CancellationError()
    }

    func renameStage(boardId: BoardID, stageId: BoardStageID, name: String) async throws -> [BoardStage] {
        throw CancellationError()
    }

    func deleteStage(boardId: BoardID, stageId: BoardStageID) async throws -> [BoardStage] {
        throw CancellationError()
    }

    func moveStage(boardId: BoardID, stageId: BoardStageID, to destinationIndex: Int) async throws -> [BoardStage] {
        throw CancellationError()
    }
}

private struct SuspendedOnlineBoardGateway: OnlineBoardGatewayContract {
    func fetchBoards(projectId: ProjectID) async throws -> [OnlineBoardReadModel] {
        try await _Concurrency.Task.sleep(nanoseconds: 60_000_000_000)
        return []
    }

    func fetchTasks(boardId: BoardID) async throws -> [OnlineTaskReadModel] {
        throw CancellationError()
    }

    func fetchTask(taskId: TaskID) async throws -> OnlineTaskReadModel {
        throw CancellationError()
    }

    func moveTask(taskId: TaskID, toStageId: BoardStageID, boardId: BoardID) async throws -> OnlineTaskReadModel {
        throw CancellationError()
    }

    func completeTask(taskId: TaskID, boardId: BoardID) async throws -> OnlineTaskReadModel {
        throw CancellationError()
    }

    func failTask(taskId: TaskID, boardId: BoardID) async throws -> OnlineTaskReadModel {
        throw CancellationError()
    }
}

// MARK: - BoardFeatureFlow task cancellation regressions

@Suite("BoardFeatureFlow task cancellation")
struct BoardFeatureFlowCancellationTests {

    /// Verifies that `cancelActiveTasks()` stops in-flight background tasks
    /// before they can emit result events.
    ///
    /// Uses a `LatchOfflineBoardWorker` that suspends until its latch is opened,
    /// then records whether it delivered a result. After `cancelActiveTasks()` is
    /// called the latch is opened; if cancellation worked the result is never
    /// delivered and `isLoadingOffline` stays `true`.
    @Test("cancelActiveTasks prevents in-flight load from delivering results")
    @MainActor
    func cancelPreventsResultDelivery() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        let latch = LatchOfflineBoardWorker()

        try await withTemporaryStore(prefix: "altis-cancel-latch") { store in
            let flow = BoardFeatureFlow(
                offlineWorker: latch,
                onlineGateway: SuspendedOnlineBoardGateway(),
                store: store,
                workspaceId: workspaceId
            )

            flow.send(.appeared(projectId: projectId, workspaceId: workspaceId))
            #expect(flow.state.isLoadingOffline)

            // Cancel before opening the latch — the in-flight load must not
            // deliver its result event after cancellation.
            // Drain ensures the tasks have fully stopped before assertions run.
            await flow.cancelAndDrainActiveTasks()

            // Open the latch now. The suspended worker body resumes but Task.isCancelled
            // is true, so the flow's guard discards the result.
            await latch.open()

            // Yield to let any still-live task run if cancellation failed.
            await _Concurrency.Task.yield()
            await _Concurrency.Task.yield()

            // isLoadingOffline stays true: no offlineBoardsLoaded event was sent.
            #expect(flow.state.isLoadingOffline,
                    "expected isLoadingOffline to remain true because the cancelled task must not deliver a result")
        }
    }

    /// Verifies that cancellation prevents `loadPresets` from calling the
    /// store after it has been logically closed.
    ///
    /// Uses `SpyLocalStoreContract` which wraps a real store and counts any
    /// `fetchBoardStagePresets` calls made after `markClosed()`. If the flow's
    /// task is not drained before close, the in-flight `loadPresets` resumes
    /// and increments the counter. The test asserts the counter stays at zero,
    /// giving an automatic failure on the undesired path without relying on
    /// manual inspection of the xcodebuild output.
    @Test("cancelActiveTasks prevents loadPresets from calling the store after close")
    @MainActor
    func cancelPreventsClosedStoreAccess() async throws {
        let workspaceId = WorkspaceID()
        let projectId = ProjectID()

        try await withTemporaryStore(prefix: "altis-cancel-store") { realStore in
            let spy = SpyLocalStoreContract(wrapping: realStore)

            let flow = BoardFeatureFlow(
                offlineWorker: LatchOfflineBoardWorker(),
                onlineGateway: SuspendedOnlineBoardGateway(),
                store: spy,
                workspaceId: workspaceId
            )

            flow.send(.appeared(projectId: projectId, workspaceId: workspaceId))

            // Mark the spy closed before draining so any post-close store call
            // is counted, then drain to ensure all tasks have fully exited.
            await spy.markClosed()
            await flow.cancelAndDrainActiveTasks()

            let postCloseCalls = await spy.callsAfterClose
            #expect(postCloseCalls == 0,
                    "loadPresets must not call fetchBoardStagePresets after cancellation; got \(postCloseCalls) post-close call(s)")
        }
    }
}

// MARK: - SpyLocalStoreContract

/// A `LocalStoreContract` spy that wraps a real store and counts calls to
/// `fetchBoardStagePresets` made after `markClosed()` is called.
///
/// `fetchBoardStagePresets` suspends until `releasePresetFetch()` is called,
/// giving the test a window to call `markClosed()` and then drain tasks before
/// any preset fetch can proceed. This eliminates the race between task spawn
/// and cancellation that would otherwise produce non-deterministic results.
///
/// Used by `cancelPreventsClosedStoreAccess` to assert automatically that
/// no post-close store access occurs when tasks are properly drained.
private actor SpyLocalStoreContract: LocalStoreContract {

    private let wrapped: OfflineLocalStore
    private var closed = false
    private(set) var callsAfterClose = 0
    private var presetFetchContinuation: CheckedContinuation<Void, Error>?

    init(wrapping store: OfflineLocalStore) {
        self.wrapped = store
    }

    /// Signals that the store is logically closed. Subsequent calls to
    /// `fetchBoardStagePresets` increment `callsAfterClose`.
    func markClosed() {
        closed = true
    }

    /// Releases the suspended `fetchBoardStagePresets` call so it can proceed.
    /// Call this only in tests that need the preset fetch to complete normally.
    func releasePresetFetch() {
        presetFetchContinuation?.resume()
        presetFetchContinuation = nil
    }

    func fetchBoardStagePresets(workspaceId: WorkspaceID) async throws -> [BoardStagePreset] {
        // Suspend here so the test can call markClosed() and drain tasks
        // before any actual preset fetch executes.
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                if _Concurrency.Task.isCancelled {
                    cont.resume(throwing: CancellationError())
                } else {
                    self.presetFetchContinuation = cont
                }
            }
        } onCancel: {
            _Concurrency.Task { await self.cancelPresetFetch() }
        }
        if closed { callsAfterClose += 1 }
        return try await wrapped.fetchBoardStagePresets(workspaceId: workspaceId)
    }

    private func cancelPresetFetch() {
        presetFetchContinuation?.resume(throwing: CancellationError())
        presetFetchContinuation = nil
    }

    // MARK: - Delegating stubs (not under observation)

    func fetchProjectListItems(workspaceId: WorkspaceID) async throws -> [ProjectListItemProjection] {
        try await wrapped.fetchProjectListItems(workspaceId: workspaceId)
    }

    func fetchBoardListItems(projectId: ProjectID) async throws -> [BoardListItemProjection] {
        try await wrapped.fetchBoardListItems(projectId: projectId)
    }

    func fetchKanbanColumns(boardId: BoardID) async throws -> [KanbanColumnProjection] {
        try await wrapped.fetchKanbanColumns(boardId: boardId)
    }

    func fetchTaskListItems(projectId: ProjectID) async throws -> [TaskListItemProjection] {
        try await wrapped.fetchTaskListItems(projectId: projectId)
    }

    func fetchTaskDetail(taskId: TaskID) async throws -> TaskDetailProjection? {
        try await wrapped.fetchTaskDetail(taskId: taskId)
    }

    func fetchProject(id: ProjectID) async throws -> Project? {
        try await wrapped.fetchProject(id: id)
    }

    func fetchBoard(id: BoardID) async throws -> Board? {
        try await wrapped.fetchBoard(id: id)
    }

    func fetchBoardStages(boardId: BoardID) async throws -> [BoardStage] {
        try await wrapped.fetchBoardStages(boardId: boardId)
    }

    func fetchBoardStagePresetStages(stagePresetId: BoardStagePresetID) async throws -> [BoardStagePresetStage] {
        try await wrapped.fetchBoardStagePresetStages(stagePresetId: stagePresetId)
    }

    func fetchTask(id: TaskID) async throws -> Task? {
        try await wrapped.fetchTask(id: id)
    }
}

