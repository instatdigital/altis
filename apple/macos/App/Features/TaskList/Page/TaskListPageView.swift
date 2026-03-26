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
                .disabled(boardMode == .online)
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

            // Stage picker — only shown when the task page flow has a loaded task
            // with stage context. For creation we derive stages from the board.
            if let task = flow.state.task, !task.boardStages.isEmpty {
                stagePicker(stages: task.boardStages)
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
        } else if let firstStage = flow.state.task?.boardStages.first {
            targetStageId = firstStage.stageId
        } else {
            // No stage context available yet — need to load it first.
            // This is the creation sheet without prior task load context.
            // We need the board's first stage. Defer to store-level default.
            // For Phase 9 with the initial task load, stages come from a loaded task.
            // This path should not be reached once the board has stages.
            return
        }

        isShowingCreateSheet = false
        flow.send(.createTaskRequested(
            title: trimmed,
            boardId: boardId,
            stageId: targetStageId,
            workspaceId: workspaceId,
            projectId: flow.state.task?.projectId ?? ProjectID()
        ))
    }
}

#Preview {
    TaskListPageView(
        flow: TaskPageFeatureFlow(
            offlineWorker: PreviewOfflineTaskPageDataWorker(),
            store: PreviewLocalWritePathContract()
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

private struct PreviewLocalWritePathContract: LocalWritePathContract {
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
