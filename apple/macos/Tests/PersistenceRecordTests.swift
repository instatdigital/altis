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
