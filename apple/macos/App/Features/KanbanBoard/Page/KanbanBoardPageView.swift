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
                    KanbanColumnView(
                        column: column,
                        onTaskSelected: { taskId in
                            flow.send(.taskSelected(taskId))
                            onTaskSelected?(taskId)
                        },
                        onTaskDropped: { taskId in
                            flow.send(.taskMoved(taskId: taskId, toStageId: column.stageId))
                        },
                        onTaskComplete: { taskId in
                            flow.send(.taskCompleteRequested(taskId))
                        },
                        onTaskFail: { taskId in
                            flow.send(.taskFailRequested(taskId))
                        }
                    )
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
        return ContentUnavailableView(
            "Online Board Unavailable",
            systemImage: "network.slash",
            description: Text(reason.message)
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
    let onTaskDropped: (TaskID) -> Void
    let onTaskComplete: (TaskID) -> Void
    let onTaskFail: (TaskID) -> Void

    /// Tracks whether a drag is hovering over this column for visual feedback.
    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            columnHeader
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 8) {
                    ForEach(column.tasks, id: \.taskId) { task in
                        KanbanTaskCardView(
                            task: task,
                            onComplete: { onTaskComplete(task.taskId) },
                            onFail: { onTaskFail(task.taskId) }
                        )
                        .contentShape(Rectangle())
                        .onTapGesture { onTaskSelected(task.taskId) }
                        .draggable(task.taskId.rawValue)
                    }
                    if column.tasks.isEmpty {
                        emptyColumn
                    }
                }
            }
        }
        .frame(width: 240, alignment: .top)
        .padding(12)
        .background(isDropTargeted
            ? Color.accentColor.opacity(0.12)
            : Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(
                    isDropTargeted ? Color.accentColor : Color.clear,
                    lineWidth: 2
                )
        )
        .dropDestination(for: String.self) { droppedItems, _ in
            guard let rawValue = droppedItems.first else { return false }
            let taskId = TaskID(rawValue: rawValue)
            onTaskDropped(taskId)
            return true
        } isTargeted: { targeted in
            isDropTargeted = targeted
        }
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
    let onComplete: () -> Void
    let onFail: () -> Void

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
            if task.status == .open {
                terminalActionButtons
            }
        }
        .padding(10)
        .background(Color(nsColor: .windowBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.06), radius: 2, x: 0, y: 1)
    }

    private var terminalActionButtons: some View {
        HStack(spacing: 6) {
            Button(action: onComplete) {
                Label("Complete", systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            .buttonStyle(.borderless)
            Button(action: onFail) {
                Label("Fail", systemImage: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            .buttonStyle(.borderless)
        }
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
            offlineWorker: PreviewOfflineKanbanWorker(),
            onlineAuthGate: PermissiveOnlineBoardAuthGate(),
            onlineGateway: NotImplementedOnlineBoardGateway()
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
