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
/// and write methods. All other `LocalStoreContract` and `LocalWritePathContract`
/// methods are present as stubs that throw `OfflineStoreError.notImplemented` —
/// they are filled in during Phases 7–13.
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
        throw OfflineStoreError.notImplemented("fetchBoardListItems — Phase 7")
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
        throw OfflineStoreError.notImplemented("fetchBoard — Phase 7")
    }

    func fetchBoardStages(boardId: BoardID) async throws -> [BoardStage] {
        throw OfflineStoreError.notImplemented("fetchBoardStages — Phase 8")
    }

    func fetchBoardStagePresetStages(stagePresetId: BoardStagePresetID) async throws -> [BoardStagePresetStage] {
        throw OfflineStoreError.notImplemented("fetchBoardStagePresetStages — Phase 7")
    }

    func fetchBoardStagePresets(workspaceId: WorkspaceID) async throws -> [BoardStagePreset] {
        throw OfflineStoreError.notImplemented("fetchBoardStagePresets — Phase 7")
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
        throw OfflineStoreError.notImplemented("createBoard — Phase 7")
    }

    func updateBoard(_ board: Board) async throws {
        throw OfflineStoreError.notImplemented("updateBoard — Phase 7")
    }

    func deleteBoard(id: BoardID) async throws {
        throw OfflineStoreError.notImplemented("deleteBoard — Phase 7")
    }

    func createBoardStage(_ stage: BoardStage) async throws {
        throw OfflineStoreError.notImplemented("createBoardStage — Phase 8")
    }

    func updateBoardStage(_ stage: BoardStage) async throws {
        throw OfflineStoreError.notImplemented("updateBoardStage — Phase 8")
    }

    func deleteBoardStage(id: BoardStageID) async throws {
        throw OfflineStoreError.notImplemented("deleteBoardStage — Phase 8")
    }

    func createBoardStagePreset(_ preset: BoardStagePreset, stages: [BoardStagePresetStage]) async throws {
        throw OfflineStoreError.notImplemented("createBoardStagePreset — Phase 7")
    }

    func updateBoardStagePreset(_ preset: BoardStagePreset) async throws {
        throw OfflineStoreError.notImplemented("updateBoardStagePreset — Phase 7")
    }

    func deleteBoardStagePreset(id: BoardStagePresetID) async throws {
        throw OfflineStoreError.notImplemented("deleteBoardStagePreset — Phase 7")
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

    /// Runs schema migrations. Must be called once immediately after `init`.
    func setup() throws {
        try migrate()
    }

    // MARK: - Migrations

    private func migrate() throws {
        try exec("PRAGMA journal_mode=WAL;")
        try exec("PRAGMA foreign_keys=ON;")
        try createProjectsTable()
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

    // MARK: - Project reads

    func fetchProjectListItems(workspaceId: String) throws -> [ProjectListItemProjection] {
        let sql = """
            SELECT projectId, name
            FROM projects
            WHERE workspaceId = ?
            ORDER BY name ASC;
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
            results.append(ProjectListItemProjection(
                projectId: ProjectID(rawValue: id),
                name: name,
                boardCount: 0
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
