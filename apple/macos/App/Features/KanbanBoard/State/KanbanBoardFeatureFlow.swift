import Foundation
import _Concurrency

/// Feature flow for the Kanban Board presentation.
///
/// Owns `KanbanBoardFeatureState` and processes `KanbanBoardFeatureEvent` values.
///
/// Board-mode routing (from `docs/SYNC_RULES.md`):
/// - `offline` boards: data loaded and mutations persisted via `OfflineKanbanDataWorker`.
/// - `online` boards: data loaded via an online gateway — routing point defined here,
///   gateway attached in Phase 14.
@MainActor
final class KanbanBoardFeatureFlow: ObservableObject {

    @Published private(set) var state = KanbanBoardFeatureState()

    private let offlineWorker: OfflineKanbanDataWorker

    init(offlineWorker: OfflineKanbanDataWorker) {
        self.offlineWorker = offlineWorker
    }

    // MARK: - Event entry point

    func send(_ event: KanbanBoardFeatureEvent) {
        switch event {
        case .appeared(let boardId, let boardMode):
            state.boardId = boardId
            state.boardMode = boardMode
            loadColumns(boardId: boardId, boardMode: boardMode)

        case .taskSelected:
            // Navigation handled by the page/shell layer.
            break

        case .taskMoved, .taskCompleteRequested, .taskFailRequested:
            // Phase 12 / Phase 13 implementation.
            break

        case .offlineColumnsLoaded(let columns):
            state.columns = columns
            state.isLoading = false

        case .onlineUnavailable(let reason):
            state.isLoading = false
            state.onlineUnavailable = reason

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Effects

    private func loadColumns(boardId: BoardID, boardMode: BoardMode) {
        state.isLoading = true
        switch boardMode {
        case .offline:
            _Concurrency.Task {
                do {
                    let columns = try await offlineWorker.loadColumns(boardId: boardId)
                    send(.offlineColumnsLoaded(columns))
                } catch {
                    send(.loadFailed(error))
                }
            }
        case .online:
            send(.onlineUnavailable(.notImplemented))
        }
    }
}
