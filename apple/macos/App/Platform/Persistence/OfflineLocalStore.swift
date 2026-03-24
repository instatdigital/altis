import Foundation
import SQLite3

// SQLITE_TRANSIENT is defined as a C macro and is not imported by Swift.
// Replicate its meaning: a destructor of (-1) tells SQLite to copy the string
// before the call returns.
private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// SQLite-backed implementation of `LocalStoreContract` and `LocalWritePathContract`.
///
/// `OfflineLocalStore` is the single durable local source of truth for offline
/// boards, projects, stages, presets, and tasks. It owns the SQLite connection
/// and serialises all access through a dedicated actor.
///
/// Phase 6 implements the project table and the `ProjectDataWorker`-facing read
/// and write methods.
/// Phase 7 implements the boards, board_stages, board_stage_presets, and
/// board_stage_preset_stages tables with full CRUD.
/// All remaining `LocalStoreContract` and `LocalWritePathContract` methods are
/// present as stubs that throw `OfflineStoreError.notImplemented` — filled in
/// during Phases 8–13.
///
/// Rules (from `docs/ARCHITECTURE.md` and `docs/SYNC_RULES.md`):
/// - Offline-board writes stay local-only.
/// - UI reads typed projections, not raw domain entities.
/// - No sync, outbox, or reconciliation logic belongs here.
final class OfflineLocalStore: Sendable {

    private let actor: DatabaseActor

    /// Creates (or opens) the local SQLite database at the given path and runs migrations.
    ///
    /// Pass `nil` to use the default application-support location.
    init(path: String? = nil) async throws {
        let resolvedPath = path ?? OfflineLocalStore.defaultDatabasePath()
        let a = try DatabaseActor(path: resolvedPath)
        try await a.setup()
        self.actor = a
    }

    /// Closes the underlying SQLite connection explicitly.
    ///
    /// Tests use this before deleting temporary database files so SQLite does
    /// not keep an open vnode reference to an unlinked file.
    func close() async {
        await actor.close()
    }

    // MARK: - Default path

    private static func defaultDatabasePath() -> String {
        let appSupport = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        let dir = appSupport.appendingPathComponent("Altis", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("altis.sqlite").path
    }
}

// MARK: - LocalStoreContract

extension OfflineLocalStore: LocalStoreContract {

    func fetchProjectListItems(workspaceId: WorkspaceID) async throws -> [ProjectListItemProjection] {
        try await actor.fetchProjectListItems(workspaceId: workspaceId.rawValue)
    }

    func fetchBoardListItems(projectId: ProjectID) async throws -> [BoardListItemProjection] {
        try await actor.fetchBoardListItems(projectId: projectId.rawValue)
    }

    func fetchKanbanColumns(boardId: BoardID) async throws -> [KanbanColumnProjection] {
        throw OfflineStoreError.notImplemented("fetchKanbanColumns — Phase 11")
    }

    func fetchTaskListItems(projectId: ProjectID) async throws -> [TaskListItemProjection] {
        throw OfflineStoreError.notImplemented("fetchTaskListItems — Phase 10")
    }

    func fetchTaskDetail(taskId: TaskID) async throws -> TaskDetailProjection? {
        throw OfflineStoreError.notImplemented("fetchTaskDetail — Phase 9")
    }

    func fetchProject(id: ProjectID) async throws -> Project? {
        try await actor.fetchProject(id: id.rawValue)
    }

    func fetchBoard(id: BoardID) async throws -> Board? {
        try await actor.fetchBoard(id: id.rawValue)
    }

    func fetchBoardStages(boardId: BoardID) async throws -> [BoardStage] {
        try await actor.fetchBoardStages(boardId: boardId.rawValue)
    }

    func fetchBoardStagePresetStages(stagePresetId: BoardStagePresetID) async throws -> [BoardStagePresetStage] {
        try await actor.fetchBoardStagePresetStages(stagePresetId: stagePresetId.rawValue)
    }

    func fetchBoardStagePresets(workspaceId: WorkspaceID) async throws -> [BoardStagePreset] {
        try await actor.fetchBoardStagePresets(workspaceId: workspaceId.rawValue)
    }

    func fetchTask(id: TaskID) async throws -> Task? {
        throw OfflineStoreError.notImplemented("fetchTask — Phase 9")
    }
}

// MARK: - LocalWritePathContract

extension OfflineLocalStore: LocalWritePathContract {

    func createProject(_ project: Project) async throws {
        try await actor.createProject(ProjectRecord(from: project))
    }

    func updateProject(_ project: Project) async throws {
        try await actor.updateProject(ProjectRecord(from: project))
    }

    func deleteProject(id: ProjectID) async throws {
        try await actor.deleteProject(id: id.rawValue)
    }

    func createBoard(_ board: Board) async throws {
        try await actor.createBoard(BoardRecord(from: board))
    }

    func updateBoard(_ board: Board) async throws {
        try await actor.updateBoard(BoardRecord(from: board))
    }

    func deleteBoard(id: BoardID) async throws {
        try await actor.deleteBoard(id: id.rawValue)
    }

    func createBoardStage(_ stage: BoardStage) async throws {
        try await actor.createBoardStage(BoardStageRecord(from: stage))
    }

    func updateBoardStage(_ stage: BoardStage) async throws {
        try await actor.updateBoardStage(BoardStageRecord(from: stage))
    }

    func deleteBoardStage(id: BoardStageID) async throws {
        try await actor.deleteBoardStage(id: id.rawValue)
    }

    func createBoardStagePreset(_ preset: BoardStagePreset, stages: [BoardStagePresetStage]) async throws {
        try await actor.createBoardStagePreset(
            BoardStagePresetRecord(from: preset),
            stages: stages.map { BoardStagePresetStageRecord(from: $0) }
        )
    }

    func updateBoardStagePreset(_ preset: BoardStagePreset) async throws {
        try await actor.updateBoardStagePreset(BoardStagePresetRecord(from: preset))
    }

    func deleteBoardStagePreset(id: BoardStagePresetID) async throws {
        try await actor.deleteBoardStagePreset(id: id.rawValue)
    }

    func createTask(_ task: Task) async throws {
        throw OfflineStoreError.notImplemented("createTask — Phase 9")
    }

    func updateTask(_ task: Task) async throws {
        throw OfflineStoreError.notImplemented("updateTask — Phase 9")
    }

    func deleteTask(id: TaskID) async throws {
        throw OfflineStoreError.notImplemented("deleteTask — Phase 9")
    }
}

// MARK: - Error

enum OfflineStoreError: LocalizedError {
    case notImplemented(String)
    case databaseError(String)
    case recordCorrupted(String)

    var errorDescription: String? {
        switch self {
        case .notImplemented(let msg): return "Not implemented: \(msg)"
        case .databaseError(let msg): return "Database error: \(msg)"
        case .recordCorrupted(let msg): return "Corrupted record: \(msg)"
        }
    }
}

// MARK: - DatabaseActor

/// Serial actor that owns the SQLite connection and serialises all database access.
private actor DatabaseActor {

    /// The raw SQLite connection handle.
    ///
    /// Marked `nonisolated(unsafe)` so that `deinit` (which runs outside actor
    /// isolation in Swift 6) can close the connection. Only `deinit` accesses
    /// this property outside actor isolation; all other accesses are from within
    /// actor-isolated methods where isolation is enforced.
    nonisolated(unsafe) private var db: OpaquePointer?

    // MARK: - Init

    /// Opens the SQLite database at `path`.
    ///
    /// In Swift 6, actor `init` is not isolated; only plain C calls that do
    /// not touch actor state are safe here. `db` is assigned through the
    /// mutable stored property directly, which is allowed because `init` owns
    /// the instance exclusively before returning. Migration is performed via
    /// the isolated `setup()` method called right after construction.
    init(path: String) throws {
        let flags = SQLITE_OPEN_CREATE | SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        var handle: OpaquePointer?
        guard sqlite3_open_v2(path, &handle, flags, nil) == SQLITE_OK, let handle else {
            if let h = handle { sqlite3_close_v2(h) }
            throw OfflineStoreError.databaseError("open: could not open database at \(path)")
        }
        self.db = handle
    }

    deinit {
        sqlite3_close_v2(db)
    }

    func close() {
        guard let db else { return }
        sqlite3_close_v2(db)
        self.db = nil
    }

    /// Runs schema migrations. Must be called once immediately after `init`.
    func setup() throws {
        try migrate()
    }

    // MARK: - Migrations

    private func migrate() throws {
        try exec("PRAGMA journal_mode=WAL;")
        try exec("PRAGMA foreign_keys=ON;")
        try createProjectsTable()
        try createBoardsTable()
        try createBoardStagesTable()
        try createBoardStagePresetsTable()
        try createBoardStagePresetStagesTable()
    }

    private func createProjectsTable() throws {
        try exec("""
            CREATE TABLE IF NOT EXISTS projects (
                projectId   TEXT PRIMARY KEY NOT NULL,
                workspaceId TEXT NOT NULL,
                name        TEXT NOT NULL,
                createdAt   TEXT NOT NULL,
                updatedAt   TEXT NOT NULL
            );
            """)
    }

    private func createBoardsTable() throws {
        try exec("""
            CREATE TABLE IF NOT EXISTS boards (
                boardId     TEXT PRIMARY KEY NOT NULL,
                workspaceId TEXT NOT NULL,
                projectId   TEXT NOT NULL,
                name        TEXT NOT NULL,
                mode        TEXT NOT NULL,
                createdAt   TEXT NOT NULL,
                updatedAt   TEXT NOT NULL
            );
            """)
    }

    private func createBoardStagesTable() throws {
        try exec("""
            CREATE TABLE IF NOT EXISTS board_stages (
                stageId    TEXT PRIMARY KEY NOT NULL,
                boardId    TEXT NOT NULL,
                name       TEXT NOT NULL,
                orderIndex INTEGER NOT NULL,
                kind       TEXT NOT NULL,
                createdAt  TEXT NOT NULL,
                updatedAt  TEXT NOT NULL
            );
            """)
    }

    private func createBoardStagePresetsTable() throws {
        try exec("""
            CREATE TABLE IF NOT EXISTS board_stage_presets (
                stagePresetId TEXT PRIMARY KEY NOT NULL,
                workspaceId   TEXT NOT NULL,
                name          TEXT NOT NULL,
                createdAt     TEXT NOT NULL,
                updatedAt     TEXT NOT NULL
            );
            """)
    }

    private func createBoardStagePresetStagesTable() throws {
        try exec("""
            CREATE TABLE IF NOT EXISTS board_stage_preset_stages (
                presetStageId TEXT PRIMARY KEY NOT NULL,
                stagePresetId TEXT NOT NULL,
                name          TEXT NOT NULL,
                orderIndex    INTEGER NOT NULL,
                kind          TEXT NOT NULL
            );
            """)
    }

    // MARK: - Project reads

    func fetchProjectListItems(workspaceId: String) throws -> [ProjectListItemProjection] {
        let sql = """
            SELECT p.projectId, p.name,
                   (SELECT COUNT(*) FROM boards b WHERE b.projectId = p.projectId) AS boardCount
            FROM projects p
            WHERE p.workspaceId = ?
            ORDER BY p.name ASC;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchProjectListItems prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, workspaceId, -1, sqliteTransient)

        var results: [ProjectListItemProjection] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = String(cString: sqlite3_column_text(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let boardCount = Int(sqlite3_column_int(stmt, 2))
            results.append(ProjectListItemProjection(
                projectId: ProjectID(rawValue: id),
                name: name,
                boardCount: boardCount
            ))
        }
        return results
    }

    func fetchProject(id: String) throws -> Project? {
        let sql = """
            SELECT projectId, workspaceId, name, createdAt, updatedAt
            FROM projects
            WHERE projectId = ?
            LIMIT 1;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchProject prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, id, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }

        let record = ProjectRecord(
            projectId:   String(cString: sqlite3_column_text(stmt, 0)),
            workspaceId: String(cString: sqlite3_column_text(stmt, 1)),
            name:        String(cString: sqlite3_column_text(stmt, 2)),
            createdAt:   String(cString: sqlite3_column_text(stmt, 3)),
            updatedAt:   String(cString: sqlite3_column_text(stmt, 4))
        )
        return record.toDomain()
    }

    // MARK: - Project writes

    func createProject(_ record: ProjectRecord) throws {
        let sql = """
            INSERT INTO projects (projectId, workspaceId, name, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("createProject prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.projectId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, record.workspaceId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, record.name, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 4, record.createdAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 5, record.updatedAt, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("createProject step")
        }
    }

    func updateProject(_ record: ProjectRecord) throws {
        let sql = """
            UPDATE projects
            SET workspaceId = ?, name = ?, updatedAt = ?
            WHERE projectId = ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("updateProject prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.workspaceId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, record.name, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, record.updatedAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 4, record.projectId, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("updateProject step")
        }
    }

    func deleteProject(id: String) throws {
        let sql = "DELETE FROM projects WHERE projectId = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("deleteProject prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, id, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("deleteProject step")
        }
    }

    // MARK: - Board reads

    func fetchBoardListItems(projectId: String) throws -> [BoardListItemProjection] {
        // Stage count is computed via a sub-query against `board_stages`.
        // Task count is always 0 here because the `tasks` table is created in Phase 9.
        // Once Phase 9 lands, replace the literal 0 with:
        //   (SELECT COUNT(*) FROM tasks t WHERE t.boardId = b.boardId)
        let sql = """
            SELECT
                b.boardId,
                b.projectId,
                b.name,
                b.mode,
                (SELECT COUNT(*) FROM board_stages s WHERE s.boardId = b.boardId) AS stageCount
            FROM boards b
            WHERE b.projectId = ?
            ORDER BY b.name ASC;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchBoardListItems prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, projectId, -1, sqliteTransient)

        var results: [BoardListItemProjection] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let boardId    = String(cString: sqlite3_column_text(stmt, 0))
            let projId     = String(cString: sqlite3_column_text(stmt, 1))
            let name       = String(cString: sqlite3_column_text(stmt, 2))
            let modeRaw    = String(cString: sqlite3_column_text(stmt, 3))
            let stageCount = Int(sqlite3_column_int(stmt, 4))
            guard let mode = BoardMode(rawValue: modeRaw) else { continue }
            results.append(BoardListItemProjection(
                boardId: BoardID(rawValue: boardId),
                projectId: ProjectID(rawValue: projId),
                name: name,
                mode: mode,
                stageCount: stageCount,
                taskCount: 0  // populated in Phase 9
            ))
        }
        return results
    }

    func fetchBoard(id: String) throws -> Board? {
        let sql = """
            SELECT boardId, workspaceId, projectId, name, mode, createdAt, updatedAt
            FROM boards
            WHERE boardId = ?
            LIMIT 1;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchBoard prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, id, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_ROW else { return nil }

        let record = BoardRecord(
            boardId:     String(cString: sqlite3_column_text(stmt, 0)),
            workspaceId: String(cString: sqlite3_column_text(stmt, 1)),
            projectId:   String(cString: sqlite3_column_text(stmt, 2)),
            name:        String(cString: sqlite3_column_text(stmt, 3)),
            mode:        String(cString: sqlite3_column_text(stmt, 4)),
            createdAt:   String(cString: sqlite3_column_text(stmt, 5)),
            updatedAt:   String(cString: sqlite3_column_text(stmt, 6))
        )
        return record.toDomain()
    }

    func fetchBoardStages(boardId: String) throws -> [BoardStage] {
        let sql = """
            SELECT stageId, boardId, name, orderIndex, kind, createdAt, updatedAt
            FROM board_stages
            WHERE boardId = ?
            ORDER BY orderIndex ASC;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchBoardStages prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, boardId, -1, sqliteTransient)

        var results: [BoardStage] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let record = BoardStageRecord(
                stageId:    String(cString: sqlite3_column_text(stmt, 0)),
                boardId:    String(cString: sqlite3_column_text(stmt, 1)),
                name:       String(cString: sqlite3_column_text(stmt, 2)),
                orderIndex: Int(sqlite3_column_int(stmt, 3)),
                kind:       String(cString: sqlite3_column_text(stmt, 4)),
                createdAt:  String(cString: sqlite3_column_text(stmt, 5)),
                updatedAt:  String(cString: sqlite3_column_text(stmt, 6))
            )
            if let stage = record.toDomain() { results.append(stage) }
        }
        return results
    }

    func fetchBoardStagePresets(workspaceId: String) throws -> [BoardStagePreset] {
        let sql = """
            SELECT stagePresetId, workspaceId, name, createdAt, updatedAt
            FROM board_stage_presets
            WHERE workspaceId = ?
            ORDER BY name ASC;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchBoardStagePresets prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, workspaceId, -1, sqliteTransient)

        var results: [BoardStagePreset] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let record = BoardStagePresetRecord(
                stagePresetId: String(cString: sqlite3_column_text(stmt, 0)),
                workspaceId:   String(cString: sqlite3_column_text(stmt, 1)),
                name:          String(cString: sqlite3_column_text(stmt, 2)),
                createdAt:     String(cString: sqlite3_column_text(stmt, 3)),
                updatedAt:     String(cString: sqlite3_column_text(stmt, 4))
            )
            if let preset = record.toDomain() { results.append(preset) }
        }
        return results
    }

    func fetchBoardStagePresetStages(stagePresetId: String) throws -> [BoardStagePresetStage] {
        let sql = """
            SELECT presetStageId, stagePresetId, name, orderIndex, kind
            FROM board_stage_preset_stages
            WHERE stagePresetId = ?
            ORDER BY orderIndex ASC;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("fetchBoardStagePresetStages prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, stagePresetId, -1, sqliteTransient)

        var results: [BoardStagePresetStage] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let record = BoardStagePresetStageRecord(
                presetStageId: String(cString: sqlite3_column_text(stmt, 0)),
                stagePresetId: String(cString: sqlite3_column_text(stmt, 1)),
                name:          String(cString: sqlite3_column_text(stmt, 2)),
                orderIndex:    Int(sqlite3_column_int(stmt, 3)),
                kind:          String(cString: sqlite3_column_text(stmt, 4))
            )
            if let stage = record.toDomain() { results.append(stage) }
        }
        return results
    }

    // MARK: - Board writes

    func createBoard(_ record: BoardRecord) throws {
        let sql = """
            INSERT INTO boards (boardId, workspaceId, projectId, name, mode, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("createBoard prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.boardId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, record.workspaceId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, record.projectId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 4, record.name, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 5, record.mode, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 6, record.createdAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 7, record.updatedAt, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("createBoard step")
        }
    }

    func updateBoard(_ record: BoardRecord) throws {
        let sql = """
            UPDATE boards
            SET workspaceId = ?, projectId = ?, name = ?, mode = ?, updatedAt = ?
            WHERE boardId = ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("updateBoard prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.workspaceId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, record.projectId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, record.name, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 4, record.mode, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 5, record.updatedAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 6, record.boardId, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("updateBoard step")
        }
    }

    func deleteBoard(id: String) throws {
        let sql = "DELETE FROM boards WHERE boardId = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("deleteBoard prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, id, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("deleteBoard step")
        }
    }

    // MARK: - BoardStage writes

    func createBoardStage(_ record: BoardStageRecord) throws {
        let sql = """
            INSERT INTO board_stages (stageId, boardId, name, orderIndex, kind, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?, ?, ?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("createBoardStage prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.stageId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, record.boardId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, record.name, -1, sqliteTransient)
        sqlite3_bind_int(stmt, 4, Int32(record.orderIndex))
        sqlite3_bind_text(stmt, 5, record.kind, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 6, record.createdAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 7, record.updatedAt, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("createBoardStage step")
        }
    }

    func updateBoardStage(_ record: BoardStageRecord) throws {
        let sql = """
            UPDATE board_stages
            SET name = ?, orderIndex = ?, kind = ?, updatedAt = ?
            WHERE stageId = ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("updateBoardStage prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.name, -1, sqliteTransient)
        sqlite3_bind_int(stmt, 2, Int32(record.orderIndex))
        sqlite3_bind_text(stmt, 3, record.kind, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 4, record.updatedAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 5, record.stageId, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("updateBoardStage step")
        }
    }

    func deleteBoardStage(id: String) throws {
        let sql = "DELETE FROM board_stages WHERE stageId = ?;"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("deleteBoardStage prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, id, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("deleteBoardStage step")
        }
    }

    // MARK: - BoardStagePreset writes

    func createBoardStagePreset(_ preset: BoardStagePresetRecord, stages: [BoardStagePresetStageRecord]) throws {
        let presetSQL = """
            INSERT INTO board_stage_presets (stagePresetId, workspaceId, name, createdAt, updatedAt)
            VALUES (?, ?, ?, ?, ?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, presetSQL, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("createBoardStagePreset prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, preset.stagePresetId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, preset.workspaceId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, preset.name, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 4, preset.createdAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 5, preset.updatedAt, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("createBoardStagePreset step")
        }

        for stage in stages {
            try createBoardStagePresetStage(stage)
        }
    }

    private func createBoardStagePresetStage(_ record: BoardStagePresetStageRecord) throws {
        let sql = """
            INSERT INTO board_stage_preset_stages (presetStageId, stagePresetId, name, orderIndex, kind)
            VALUES (?, ?, ?, ?, ?);
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("createBoardStagePresetStage prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, record.presetStageId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, record.stagePresetId, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, record.name, -1, sqliteTransient)
        sqlite3_bind_int(stmt, 4, Int32(record.orderIndex))
        sqlite3_bind_text(stmt, 5, record.kind, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("createBoardStagePresetStage step")
        }
    }

    func updateBoardStagePreset(_ preset: BoardStagePresetRecord) throws {
        let sql = """
            UPDATE board_stage_presets
            SET name = ?, updatedAt = ?
            WHERE stagePresetId = ?;
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            throw sqliteError("updateBoardStagePreset prepare")
        }
        defer { sqlite3_finalize(stmt) }

        sqlite3_bind_text(stmt, 1, preset.name, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 2, preset.updatedAt, -1, sqliteTransient)
        sqlite3_bind_text(stmt, 3, preset.stagePresetId, -1, sqliteTransient)

        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw sqliteError("updateBoardStagePreset step")
        }
    }

    func deleteBoardStagePreset(id: String) throws {
        // Delete preset stages first (no FK cascade in SQLite by default).
        let stagesSQL = "DELETE FROM board_stage_preset_stages WHERE stagePresetId = ?;"
        var stagesStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, stagesSQL, -1, &stagesStmt, nil) == SQLITE_OK else {
            throw sqliteError("deleteBoardStagePreset stages prepare")
        }
        defer { sqlite3_finalize(stagesStmt) }
        sqlite3_bind_text(stagesStmt, 1, id, -1, sqliteTransient)
        guard sqlite3_step(stagesStmt) == SQLITE_DONE else {
            throw sqliteError("deleteBoardStagePreset stages step")
        }

        let presetSQL = "DELETE FROM board_stage_presets WHERE stagePresetId = ?;"
        var presetStmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, presetSQL, -1, &presetStmt, nil) == SQLITE_OK else {
            throw sqliteError("deleteBoardStagePreset preset prepare")
        }
        defer { sqlite3_finalize(presetStmt) }
        sqlite3_bind_text(presetStmt, 1, id, -1, sqliteTransient)
        guard sqlite3_step(presetStmt) == SQLITE_DONE else {
            throw sqliteError("deleteBoardStagePreset preset step")
        }
    }

    // MARK: - Helpers

    private func exec(_ sql: String) throws {
        var errMsg: UnsafeMutablePointer<CChar>?
        let rc = sqlite3_exec(db, sql, nil, nil, &errMsg)
        if rc != SQLITE_OK {
            let msg = errMsg.map { String(cString: $0) } ?? "unknown"
            sqlite3_free(errMsg)
            throw OfflineStoreError.databaseError(msg)
        }
    }

    private func sqliteError(_ context: String) -> OfflineStoreError {
        let msg = db.map { String(cString: sqlite3_errmsg($0)) } ?? "unknown"
        return .databaseError("\(context): \(msg)")
    }
}
