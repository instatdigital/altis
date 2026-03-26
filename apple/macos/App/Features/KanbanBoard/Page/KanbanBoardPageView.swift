import SwiftUI

/// Kanban board page — Phase 11 implementation.
///
/// Renders one column per board stage in `orderIndex` order.
/// Each column shows its tasks as cards with a compact stage-progress line.
/// Tapping a card emits `taskSelected` and calls `onTaskSelected` for navigation.
struct KanbanBoardPageView: View {

    @ObservedObject var flow: KanbanBoardFeatureFlow

    let boardId: BoardID
    let boardMode: BoardMode
    var onTaskSelected: ((TaskID) -> Void)?

    var body: some View {
        Group {
            if flow.state.isLoading && flow.state.columns.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let reason = flow.state.onlineUnavailable {
                onlineUnavailableView(reason: reason)
            } else if let error = flow.state.errorMessage {
                errorView(message: error)
            } else if flow.state.columns.isEmpty {
                emptyState
            } else {
                kanbanBoard
            }
        }
        .navigationTitle("Kanban")
        .onAppear {
            flow.send(.appeared(boardId: boardId, boardMode: boardMode))
        }
    }

    // MARK: - Subviews

    private var kanbanBoard: some View {
        ScrollView(.horizontal, showsIndicators: true) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(flow.state.columns) { column in
                    KanbanColumnView(column: column) { taskId in
                        flow.send(.taskSelected(taskId))
                        onTaskSelected?(taskId)
                    }
                }
            }
            .padding(16)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Stages",
            systemImage: "rectangle.split.3x1",
            description: Text("Add stages to this board to see the kanban view.")
        )
    }

    private func onlineUnavailableView(reason: OnlineBoardUnavailableReason) -> some View {
        ContentUnavailableView(
            "Online Board Unavailable",
            systemImage: "network.slash",
            description: Text(reason.localizedDescription)
        )
    }

    private func errorView(message: String) -> some View {
        ContentUnavailableView(
            "Error",
            systemImage: "exclamationmark.triangle",
            description: Text(message)
        )
    }
}

// MARK: - Column view

private struct KanbanColumnView: View {

    let column: KanbanColumnProjection
    let onTaskSelected: (TaskID) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            columnHeader
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(column.tasks, id: \.taskId) { task in
                        KanbanTaskCardView(task: task)
                            .contentShape(Rectangle())
                            .onTapGesture { onTaskSelected(task.taskId) }
                    }
                    if column.tasks.isEmpty {
                        emptyColumn
                    }
                }
            }
        }
        .frame(width: 240, alignment: .top)
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private var columnHeader: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(headerColor)
                .frame(width: 8, height: 8)
            Text(column.stageName)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text("\(column.tasks.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var headerColor: Color {
        switch column.stageKind {
        case .terminalSuccess: return .green
        case .terminalFailure: return .red
        default:               return .accentColor
        }
    }

    private var emptyColumn: some View {
        Text("No tasks")
            .font(.caption)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
    }
}

// MARK: - Task card view

private struct KanbanTaskCardView: View {

    let task: TaskListItemProjection

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                statusIcon
                Text(task.title)
                    .font(.body)
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            stageProgress
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }

    private var statusIcon: some View {
        Image(systemName: statusImageName)
            .foregroundStyle(statusColor)
            .frame(width: 16)
    }

    private var statusImageName: String {
        switch task.status {
        case .open:      return "circle"
        case .completed: return "checkmark.circle.fill"
        case .failed:    return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .open:      return .secondary
        case .completed: return .green
        case .failed:    return .red
        }
    }

    @ViewBuilder
    private var stageProgress: some View {
        if let orderIndex = task.stageOrderIndex,
           let total = task.totalStageCount,
           total > 0 {
            HStack(spacing: 3) {
                ForEach(0 ..< total, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(index <= orderIndex ? progressFillColor : Color.secondary.opacity(0.25))
                        .frame(height: 3)
                }
            }
        }
    }

    private var progressFillColor: Color {
        switch task.stageKind {
        case .terminalSuccess: return .green
        case .terminalFailure: return .red
        default:               return .accentColor
        }
    }
}

// MARK: - Preview

#Preview {
    KanbanBoardPageView(
        flow: KanbanBoardFeatureFlow(
            offlineWorker: PreviewOfflineKanbanWorker()
        ),
        boardId: BoardID(),
        boardMode: .offline
    )
}

private struct PreviewOfflineKanbanWorker: OfflineKanbanDataWorker {
    func loadColumns(boardId: BoardID) async throws -> [KanbanColumnProjection] { [] }
    func moveTask(taskId: TaskID, toStageId: BoardStageID, boardId: BoardID) async throws {}
    func completeTask(taskId: TaskID, boardId: BoardID) async throws {}
    func failTask(taskId: TaskID, boardId: BoardID) async throws {}
}
