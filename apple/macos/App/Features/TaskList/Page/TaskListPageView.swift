import SwiftUI

/// Task list page for a single board.
///
/// Phase 9: Provides the create-task entry point. Task rows are listed
/// as a loading placeholder; full task list rendering is Phase 10.
///
/// Renders state from `TaskPageFeatureFlow` (which owns both task creation
/// and task detail). All user intents are emitted as `TaskPageFeatureEvent`
/// values — the view never mutates data directly.
struct TaskListPageView: View {

    @ObservedObject var flow: TaskPageFeatureFlow

    let boardId: BoardID
    let boardMode: BoardMode
    let workspaceId: WorkspaceID
    /// Called when the user taps a task row to open its detail page.
    var onTaskSelected: ((TaskID) -> Void)?

    @State private var isShowingCreateSheet = false
    @State private var newTaskTitle = ""
    @State private var selectedStageId: BoardStageID? = nil

    var body: some View {
        Group {
            emptyState
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
                .disabled(boardMode == .online || flow.state.boardStages.isEmpty)
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            createTaskSheet
        }
        .alert("Error", isPresented: Binding(
            get: { flow.state.errorMessage != nil },
            set: { if !$0 { flow.send(.errorAcknowledged) } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(flow.state.errorMessage ?? "")
        }
        .onAppear {
            if boardMode == .offline {
                flow.send(.boardContextLoaded(boardId: boardId, boardMode: boardMode))
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

    private var createTaskSheet: some View {
        VStack(spacing: 20) {
            Text("New Task")
                .font(.headline)

            TextField("Task title", text: $newTaskTitle)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submitCreate() }

            if !flow.state.boardStages.isEmpty {
                stagePicker(stages: flow.state.boardStages)
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
                    || flow.state.isCreating
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
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

        // Resolve target stage: use selected stage or the first stage of the board.
        let targetStageId: BoardStageID
        if let sid = selectedStageId {
            targetStageId = sid
        } else if let firstStage = flow.state.boardStages.first {
            targetStageId = firstStage.stageId
        } else {
            // Stage context not yet loaded — button should be disabled in this state.
            return
        }

        guard let projectId = flow.state.activeProjectId else { return }

        isShowingCreateSheet = false
        flow.send(.createTaskRequested(
            title: trimmed,
            boardId: boardId,
            stageId: targetStageId,
            workspaceId: workspaceId,
            projectId: projectId
        ))
    }
}

#Preview {
    TaskListPageView(
        flow: TaskPageFeatureFlow(
            offlineWorker: PreviewOfflineTaskPageDataWorker(),
            store: PreviewStore()
        ),
        boardId: BoardID(),
        boardMode: .offline,
        workspaceId: WorkspaceID()
    )
}

// MARK: - Preview helpers

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
    // LocalStoreContract
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
    // LocalWritePathContract
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
