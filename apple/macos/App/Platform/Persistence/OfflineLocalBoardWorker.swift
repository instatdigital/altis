import Foundation

/// Concrete `OfflineBoardDataWorker` backed by `OfflineLocalStore`.
///
/// Creates and loads offline boards using local SQLite persistence.
/// When a board is created without a preset, three default stages are
/// generated to satisfy the board-stage invariants:
///   - "To Do"     (regular, orderIndex 0)
///   - "Done"      (terminalSuccess, orderIndex 1)
///   - "Cancelled" (terminalFailure, orderIndex 2)
///
/// When a board is created from a preset, its stages are copied verbatim
/// from the preset's `BoardStagePresetStage` definitions. Invariants are
/// validated before any write.
///
/// Rules (from `docs/ARCHITECTURE.md`):
/// - Data workers MUST encapsulate data access behind typed interfaces.
/// - UI-facing code MUST NOT call persistence or transport directly.
struct OfflineLocalBoardWorker: OfflineBoardDataWorker {

    private let store: OfflineLocalStore

    init(store: OfflineLocalStore) {
        self.store = store
    }

    // MARK: - OfflineBoardDataWorker

    func loadBoards(projectId: ProjectID) async throws -> [BoardListItemProjection] {
        // Delegate to the store's projection read so that store-computed fields
        // (stageCount, taskCount) reach the feature flow intact.
        try await store.fetchBoardListItems(projectId: projectId)
    }

    func createBoard(
        name: String,
        projectId: ProjectID,
        workspaceId: WorkspaceID
    ) async throws -> Board {
        let now = Date()
        let board = Board(
            boardId: BoardID(),
            workspaceId: workspaceId,
            projectId: projectId,
            name: name,
            mode: .offline,
            createdAt: now,
            updatedAt: now
        )

        let stages = defaultStages(for: board.boardId, now: now)

        // Validate invariants before writing.
        switch BoardStageInvariants.validate(stages) {
        case .success: break
        case .failure(let violation):
            throw OfflineBoardWorkerError.invariantViolation(violation.description)
        }

        try await store.createBoard(board)
        for stage in stages {
            try await store.createBoardStage(stage)
        }
        return board
    }

    func createBoardFromPreset(
        name: String,
        projectId: ProjectID,
        workspaceId: WorkspaceID,
        preset: BoardStagePreset,
        presetStages: [BoardStagePresetStage]
    ) async throws -> Board {
        let now = Date()
        let board = Board(
            boardId: BoardID(),
            workspaceId: workspaceId,
            projectId: projectId,
            name: name,
            mode: .offline,
            createdAt: now,
            updatedAt: now
        )

        // Copy preset stages into board-local BoardStage entities.
        let stages: [BoardStage] = presetStages
            .sorted { $0.orderIndex < $1.orderIndex }
            .enumerated()
            .map { (index, presetStage) in
                BoardStage(
                    stageId: BoardStageID(),
                    boardId: board.boardId,
                    name: presetStage.name,
                    orderIndex: index,
                    kind: presetStage.kind,
                    createdAt: now,
                    updatedAt: now
                )
            }

        // Validate invariants before writing.
        switch BoardStageInvariants.validate(stages) {
        case .success: break
        case .failure(let violation):
            throw OfflineBoardWorkerError.invariantViolation(violation.description)
        }

        try await store.createBoard(board)
        for stage in stages {
            try await store.createBoardStage(stage)
        }
        return board
    }

    // MARK: - Default stages

    /// Returns the canonical three-stage default set for a new offline board.
    private func defaultStages(for boardId: BoardID, now: Date) -> [BoardStage] {
        [
            BoardStage(
                stageId: BoardStageID(),
                boardId: boardId,
                name: "To Do",
                orderIndex: 0,
                kind: .regular,
                createdAt: now,
                updatedAt: now
            ),
            BoardStage(
                stageId: BoardStageID(),
                boardId: boardId,
                name: "Done",
                orderIndex: 1,
                kind: .terminalSuccess,
                createdAt: now,
                updatedAt: now
            ),
            BoardStage(
                stageId: BoardStageID(),
                boardId: boardId,
                name: "Cancelled",
                orderIndex: 2,
                kind: .terminalFailure,
                createdAt: now,
                updatedAt: now
            ),
        ]
    }
}

// MARK: - Errors

enum OfflineBoardWorkerError: LocalizedError {
    case invariantViolation(String)

    var errorDescription: String? {
        switch self {
        case .invariantViolation(let message):
            return "Board stage invariant violated: \(message)"
        }
    }
}
