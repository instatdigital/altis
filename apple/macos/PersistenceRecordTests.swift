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
