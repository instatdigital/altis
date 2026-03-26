import SwiftUI

/// Full task detail page for an offline board task.
///
/// Renders the `TaskPageFeatureState` provided by `TaskPageFeatureFlow`.
/// All user intents are emitted as `TaskPageFeatureEvent` values — the view
/// never mutates data directly.
///
/// Shows:
/// - Task title
/// - Compact stage-progress line (all stages in order; current stage highlighted)
/// - Current stage name
/// - Task status badge
/// - Stage move picker (offline only)
/// - Complete / Fail actions (Phase 13 — buttons wired, logic deferred)
struct TaskPageView: View {

    @ObservedObject var flow: TaskPageFeatureFlow

    var body: some View {
        Group {
            if flow.state.isLoading && flow.state.task == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let task = flow.state.task {
                taskDetail(task)
            } else if let reason = flow.state.onlineUnavailable {
                onlineUnavailableView(reason)
            } else {
                ContentUnavailableView(
                    "Task not found",
                    systemImage: "doc.text",
                    description: Text("This task could not be loaded.")
                )
            }
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

    // MARK: - Task detail

    @ViewBuilder
    private func taskDetail(_ task: TaskDetailProjection) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Title
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.semibold)

                // Status badge
                statusBadge(task.status)

                Divider()

                // Stage progress line
                if !task.boardStages.isEmpty {
                    stageProgressSection(task)
                }

                Divider()

                // Metadata
                metadataSection(task)
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle(task.title)
    }

    // MARK: - Stage progress

    @ViewBuilder
    private func stageProgressSection(_ task: TaskDetailProjection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Stage")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            // Compact stage-progress line
            stageProgressLine(task)

            // Stage move picker
            if flow.state.boardMode == .offline {
                stagePicker(task)
            }
        }
    }

    @ViewBuilder
    private func stageProgressLine(_ task: TaskDetailProjection) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(task.boardStages.enumerated()), id: \.element.stageId) { index, stage in
                let isCurrent = stage.stageId == task.currentStage?.stageId
                let isPast = isPastStage(stage, in: task)

                HStack(spacing: 0) {
                    // Connector line (except for the first stage)
                    if index > 0 {
                        Rectangle()
                            .fill(isPast || isCurrent ? stageColor(stage: stage, task: task, position: index) : Color.secondary.opacity(0.3))
                            .frame(height: 2)
                            .frame(maxWidth: .infinity)
                    }

                    // Stage dot
                    Circle()
                        .fill(isCurrent ? stageDotColor(stage) : (isPast ? Color.secondary.opacity(0.5) : Color.secondary.opacity(0.2)))
                        .frame(width: isCurrent ? 12 : 8, height: isCurrent ? 12 : 8)
                        .overlay {
                            if isCurrent {
                                Circle()
                                    .strokeBorder(stageDotColor(stage), lineWidth: 2)
                                    .frame(width: 16, height: 16)
                            }
                        }
                }
            }
        }
        .frame(height: 20)

        // Stage name label
        if let currentStage = task.currentStage {
            Text(currentStage.name)
                .font(.caption)
                .foregroundStyle(stageDotColor(currentStage))
        }
    }

    @ViewBuilder
    private func stagePicker(_ task: TaskDetailProjection) -> some View {
        let regularStages = task.boardStages.filter { !$0.isTerminal }
        if !regularStages.isEmpty || !task.boardStages.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Move to stage")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Picker("Stage", selection: Binding(
                    get: { task.currentStage?.stageId },
                    set: { newId in
                        if let id = newId, id != task.currentStage?.stageId {
                            flow.send(.stageMoveRequested(stageId: id))
                        }
                    }
                )) {
                    ForEach(task.boardStages, id: \.stageId) { stage in
                        HStack {
                            Text(stage.name)
                            Text(kindLabel(stage.kind))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(Optional(stage.stageId))
                    }
                }
                .pickerStyle(.menu)
                .disabled(flow.state.isLoading)
            }
        }
    }

    // MARK: - Status badge

    @ViewBuilder
    private func statusBadge(_ status: TaskStatus) -> some View {
        Text(statusLabel(status))
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(statusColor(status).opacity(0.15)))
            .foregroundStyle(statusColor(status))
    }

    // MARK: - Metadata

    @ViewBuilder
    private func metadataSection(_ task: TaskDetailProjection) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Details")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LabeledContent("Created", value: task.createdAt.formatted(date: .abbreviated, time: .shortened))
            LabeledContent("Updated", value: task.updatedAt.formatted(date: .abbreviated, time: .shortened))
        }
    }

    // MARK: - Online unavailable

    @ViewBuilder
    private func onlineUnavailableView(_ reason: OnlineBoardUnavailableReason) -> some View {
        ContentUnavailableView(
            "Online Board Unavailable",
            systemImage: "cloud.slash",
            description: Text(onlineUnavailableDescription(reason))
        )
    }

    // MARK: - Helpers

    private func isPastStage(_ stage: BoardStage, in task: TaskDetailProjection) -> Bool {
        guard let currentIndex = task.boardStages.firstIndex(where: { $0.stageId == task.currentStage?.stageId }),
              let stageIndex = task.boardStages.firstIndex(where: { $0.stageId == stage.stageId }) else {
            return false
        }
        return stageIndex < currentIndex
    }

    private func stageColor(stage: BoardStage, task: TaskDetailProjection, position: Int) -> Color {
        guard let currentIndex = task.boardStages.firstIndex(where: { $0.stageId == task.currentStage?.stageId }) else {
            return Color.secondary.opacity(0.3)
        }
        return position <= currentIndex ? Color.secondary.opacity(0.5) : Color.secondary.opacity(0.3)
    }

    private func stageDotColor(_ stage: BoardStage) -> Color {
        switch stage.kind {
        case .regular: return .accentColor
        case .terminalSuccess: return .green
        case .terminalFailure: return .red
        }
    }

    private func statusLabel(_ status: TaskStatus) -> String {
        switch status {
        case .open: return "Open"
        case .completed: return "Completed"
        case .failed: return "Failed"
        }
    }

    private func statusColor(_ status: TaskStatus) -> Color {
        switch status {
        case .open: return .accentColor
        case .completed: return .green
        case .failed: return .red
        }
    }

    private func kindLabel(_ kind: BoardStageKind) -> String {
        switch kind {
        case .regular: return ""
        case .terminalSuccess: return "✓"
        case .terminalFailure: return "✗"
        }
    }

    private func onlineUnavailableDescription(_ reason: OnlineBoardUnavailableReason) -> String {
        switch reason {
        case .networkUnavailable: return "Network is not available. This task requires an online connection."
        case .notAuthenticated: return "Sign in to access this board."
        case .notImplemented: return "Online boards are available in a later phase."
        }
    }
}

#Preview {
    let stage1 = BoardStage(boardId: BoardID(), name: "To Do", orderIndex: 0, kind: .regular)
    let stage2 = BoardStage(boardId: BoardID(), name: "In Progress", orderIndex: 1, kind: .regular)
    let stage3 = BoardStage(boardId: BoardID(), name: "Done", orderIndex: 2, kind: .terminalSuccess)
    let projection = TaskDetailProjection(
        task: Task(
            workspaceId: WorkspaceID(),
            projectId: ProjectID(),
            boardId: stage1.boardId,
            stageId: stage2.stageId,
            title: "Sample Task"
        ),
        boardStages: [stage1, stage2, stage3]
    )

    // Create a preview-only flow that has the projection pre-loaded.
    // We can't inject state directly, so use a helper view that triggers appeared.
    Text("Preview requires a live store — see TaskPageView implementation")
        .frame(width: 400, height: 300)
}
