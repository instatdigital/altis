import SwiftUI

/// Task list page for a single board.
///
/// Phase 10: Renders the offline task list from `TaskListFeatureFlow`.
/// Shows task title and current stage for each row.
/// Supports opening `TaskPage` from a task row.
///
/// `TaskPageFeatureFlow` owns task creation and detail.
/// `TaskListFeatureFlow` owns list data loading.
/// All user intents are emitted as typed events — the view never mutates data directly.
struct TaskListPageView: View {

    @ObservedObject var taskListFlow: TaskListFeatureFlow
    @ObservedObject var taskPageFlow: TaskPageFeatureFlow

    let boardId: BoardID
    let boardMode: BoardMode
    let workspaceId: WorkspaceID
    /// Called when the user taps a task row to open its detail page.
    var onTaskSelected: ((TaskID) -> Void)?
    /// Called when the user requests the kanban view for this board.
    var onKanbanRequested: (() -> Void)?

    @State private var isShowingCreateSheet = false
    @State private var newTaskTitle = ""
    @State private var selectedStageId: BoardStageID? = nil

    var body: some View {
        Group {
            if taskListFlow.state.isLoading && taskListFlow.state.tasks.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if taskListFlow.state.tasks.isEmpty {
                emptyState
            } else {
                taskList
            }
        }
        .navigationTitle("Tasks")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newTaskTitle = ""
                    selectedStageId = nil
                    isShowingCreateSheet = true
                } label: {
                    Label("New Task", systemImage: "plus")
                }
                .disabled(boardMode == .online || taskPageFlow.state.boardStages.isEmpty)
            }
            ToolbarItem(placement: .secondaryAction) {
                Button {
                    onKanbanRequested?()
                } label: {
                    Label("Kanban View", systemImage: "rectangle.split.3x1")
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            createTaskSheet
        }
        .alert("Error", isPresented: Binding(
            get: { taskPageFlow.state.errorMessage != nil },
            set: { if !$0 { taskPageFlow.send(.errorAcknowledged) } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(taskPageFlow.state.errorMessage ?? "")
        }
        .onAppear {
            if boardMode == .offline {
                taskListFlow.send(.appeared(boardId: boardId, boardMode: boardMode))
                taskPageFlow.send(.boardContextLoaded(boardId: boardId, boardMode: boardMode))
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Tasks",
            systemImage: "checklist",
            description: Text(boardMode == .offline
                ? "Create your first task using the + button."
                : "Online task list — available in Phase 14.")
        )
    }

    private var taskList: some View {
        List(taskListFlow.state.tasks, id: \.taskId) { task in
            TaskListRowView(projection: task)
                .contentShape(Rectangle())
                .onTapGesture {
                    taskListFlow.send(.taskSelected(task.taskId))
                    onTaskSelected?(task.taskId)
                }
        }
    }

    private var createTaskSheet: some View {
        VStack(spacing: 20) {
            Text("New Task")
                .font(.headline)

            TextField("Task title", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submitCreate() }

            if !taskPageFlow.state.boardStages.isEmpty {
                stagePicker(stages: taskPageFlow.state.boardStages)
            }

            HStack {
                Button("Cancel", role: .cancel) {
                    isShowingCreateSheet = false
                }
                Spacer()
                Button("Create") {
                    submitCreate()
                }
                .disabled(
                    newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || taskPageFlow.state.isCreating
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
        .onChange(of: taskPageFlow.state.isCreating) { _, isCreating in
            // Refresh the list after task creation finishes.
            if !isCreating && taskPageFlow.state.errorMessage == nil {
                taskListFlow.send(.appeared(boardId: boardId, boardMode: boardMode))
            }
        }
    }

    @ViewBuilder
    private func stagePicker(stages: [BoardStage]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stage")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Stage", selection: $selectedStageId) {
                Text("First stage (default)").tag(BoardStageID?.none)
                ForEach(stages, id: \.stageId) { stage in
                    Text(stage.name).tag(Optional(stage.stageId))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    // MARK: - Actions

    private func submitCreate() {
        let trimmed = newTaskTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let targetStageId: BoardStageID
        if let sid = selectedStageId {
            targetStageId = sid
        } else if let firstStage = taskPageFlow.state.boardStages.first {
            targetStageId = firstStage.stageId
        } else {
            return
        }

        guard let projectId = taskPageFlow.state.activeProjectId else { return }

        isShowingCreateSheet = false
        taskPageFlow.send(.createTaskRequested(
            title: trimmed,
            boardId: boardId,
            stageId: targetStageId,
            workspaceId: workspaceId,
            projectId: projectId
        ))
    }
}

// MARK: - Task row

private struct TaskListRowView: View {

    let projection: TaskListItemProjection

    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            VStack(alignment: .leading, spacing: 3) {
                Text(projection.title)
                    .font(.body)
                    .lineLimit(2)
                if let stageName = projection.stageName {
                    stageLabel(name: stageName)
                }
            }
            Spacer()
            stageProgress
        }
        .padding(.vertical, 4)
    }

    private var statusIcon: some View {
        Image(systemName: statusImageName)
            .foregroundStyle(statusColor)
            .frame(width: 20)
    }

    private var statusImageName: String {
        switch projection.status {
        case .open:      return "circle"
        case .completed: return "checkmark.circle.fill"
        case .failed:    return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch projection.status {
        case .open:      return .secondary
        case .completed: return .green
        case .failed:    return .red
        }
    }

    @ViewBuilder
    private func stageLabel(name: String) -> some View {
        let kind = projection.stageKind
        Text(name)
            .font(.caption)
            .foregroundStyle(stageLabelColor(for: kind))
    }

    private func stageLabelColor(for kind: BoardStageKind?) -> Color {
        switch kind {
        case .terminalSuccess: return .green
        case .terminalFailure: return .red
        default:               return .secondary
        }
    }

    @ViewBuilder
    private var stageProgress: some View {
        if let orderIndex = projection.stageOrderIndex,
           let total = projection.totalStageCount,
           total > 0 {
            Text("\(orderIndex + 1)/\(total)")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
    }
}

#Preview {
    TaskListPageView(
        taskListFlow: TaskListFeatureFlow(
            offlineWorker: PreviewOfflineTaskListWorker()
        ),
        taskPageFlow: TaskPageFeatureFlow(
            offlineWorker: PreviewOfflineTaskPageDataWorker(),
            store: PreviewStore()
        ),
        boardId: BoardID(),
        boardMode: .offline,
        workspaceId: WorkspaceID()
    )
}

// MARK: - Preview helpers

private struct PreviewOfflineTaskListWorker: OfflineTaskListDataWorker {
    func loadTasks(boardId: BoardID) async throws -> [TaskListItemProjection] {
        []
    }
}

private struct PreviewOfflineTaskPageDataWorker: OfflineTaskPageDataWorker {
    func loadTask(taskId: TaskID) async throws -> TaskDetailProjection {
        throw CancellationError()
    }
    func moveTask(taskId: TaskID, toStageId: BoardStageID) async throws -> TaskDetailProjection {
        throw CancellationError()
    }
    func completeTask(taskId: TaskID) async throws -> TaskDetailProjection {
        throw CancellationError()
    }
    func failTask(taskId: TaskID) async throws -> TaskDetailProjection {
        throw CancellationError()
    }
}

private struct PreviewStore: LocalStoreContract, LocalWritePathContract {
    func fetchProjectListItems(workspaceId: WorkspaceID) async throws -> [ProjectListItemProjection] { [] }
    func fetchBoardListItems(projectId: ProjectID) async throws -> [BoardListItemProjection] { [] }
    func fetchKanbanColumns(boardId: BoardID) async throws -> [KanbanColumnProjection] { [] }
    func fetchTaskListItems(boardId: BoardID) async throws -> [TaskListItemProjection] { [] }
    func fetchTaskDetail(taskId: TaskID) async throws -> TaskDetailProjection? { nil }
    func fetchProject(id: ProjectID) async throws -> Project? { nil }
    func fetchBoard(id: BoardID) async throws -> Board? { nil }
    func fetchBoardStages(boardId: BoardID) async throws -> [BoardStage] { [] }
    func fetchBoardStagePresetStages(stagePresetId: BoardStagePresetID) async throws -> [BoardStagePresetStage] { [] }
    func fetchBoardStagePresets(workspaceId: WorkspaceID) async throws -> [BoardStagePreset] { [] }
    func fetchTask(id: TaskID) async throws -> Task? { nil }
    func createProject(_ project: Project) async throws {}
    func updateProject(_ project: Project) async throws {}
    func deleteProject(id: ProjectID) async throws {}
    func createBoard(_ board: Board) async throws {}
    func updateBoard(_ board: Board) async throws {}
    func deleteBoard(id: BoardID) async throws {}
    func createBoardStage(_ stage: BoardStage) async throws {}
    func updateBoardStage(_ stage: BoardStage) async throws {}
    func deleteBoardStage(id: BoardStageID) async throws {}
    func createBoardStagePreset(_ preset: BoardStagePreset, stages: [BoardStagePresetStage]) async throws {}
    func updateBoardStagePreset(_ preset: BoardStagePreset) async throws {}
    func deleteBoardStagePreset(id: BoardStagePresetID) async throws {}
    func createTask(_ task: Task) async throws {}
    func updateTask(_ task: Task) async throws {}
    func deleteTask(id: TaskID) async throws {}
}
