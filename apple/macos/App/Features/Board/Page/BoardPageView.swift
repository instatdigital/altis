import SwiftUI

/// Board list and creation surface for a project.
///
/// Renders the `BoardFeatureState` provided by `BoardFeatureFlow`.
/// All user intents are emitted as `BoardFeatureEvent` values — the view
/// never mutates data directly.
///
/// The creation sheet exposes a `BoardMode` picker. Selecting `.offline`
/// creates a local board immediately. Selecting `.online` is shown but
/// disabled — wired in Phase 14.
struct BoardPageView: View {

    @ObservedObject var flow: BoardFeatureFlow

    let projectId: ProjectID
    let workspaceId: WorkspaceID

    @State private var isShowingCreateSheet = false
    @State private var newBoardName = ""
    @State private var selectedMode: BoardMode = .offline
    @State private var selectedPresetId: BoardStagePresetID? = nil

    var body: some View {
        Group {
            if flow.state.isLoadingOffline && flow.state.boards.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if flow.state.boards.isEmpty {
                emptyState
            } else {
                boardList
            }
        }
        .navigationTitle("Boards")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newBoardName = ""
                    selectedMode = .offline
                    selectedPresetId = nil
                    isShowingCreateSheet = true
                } label: {
                    Label("New Board", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            createBoardSheet
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
            flow.send(.appeared(projectId: projectId, workspaceId: workspaceId))
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Boards",
            systemImage: "square.grid.3x1.below.line.grid.1x2",
            description: Text("Create your first board to organise tasks.")
        )
    }

    private var boardList: some View {
        List(flow.state.boards, id: \.boardId) { board in
            BoardRowView(projection: board)
                .onTapGesture {
                    flow.send(.boardSelected(board.boardId))
                }
        }
    }

    private var createBoardSheet: some View {
        VStack(spacing: 20) {
            Text("New Board")
                .font(.headline)

            TextField("Board name", text: $newBoardName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submitCreate() }

            modePicker

            if selectedMode == .offline && !flow.state.availablePresets.isEmpty {
                presetPicker
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
                    newBoardName.trimmingCharacters(in: .whitespaces).isEmpty
                    || flow.state.isCreating
                    || selectedMode == .online
                )
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 320)
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Board type")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Board type", selection: $selectedMode) {
                Text("Local (offline)").tag(BoardMode.offline)
                Text("Online (Phase 14)").tag(BoardMode.online)
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            if selectedMode == .online {
                Text("Online boards are not available yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var presetPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Start from preset (optional)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Picker("Preset", selection: $selectedPresetId) {
                Text("Default (3-stage)").tag(BoardStagePresetID?.none)
                ForEach(flow.state.availablePresets, id: \.stagePresetId) { preset in
                    Text(preset.name).tag(BoardStagePresetID?.some(preset.stagePresetId))
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
        }
    }

    // MARK: - Actions

    private func submitCreate() {
        let trimmed = newBoardName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, selectedMode == .offline else { return }
        isShowingCreateSheet = false

        if let presetId = selectedPresetId {
            flow.send(.createOfflineBoardFromPresetRequested(
                name: trimmed,
                projectId: projectId,
                presetId: presetId
            ))
        } else {
            flow.send(.createOfflineBoardRequested(name: trimmed, projectId: projectId))
        }
    }
}

// MARK: - Board row

private struct BoardRowView: View {

    let projection: BoardListItemProjection

    var body: some View {
        HStack {
            Image(systemName: modeIcon)
                .foregroundStyle(modeColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(projection.name)
                    .font(.body)
                HStack(spacing: 8) {
                    if projection.stageCount > 0 {
                        Text("\(projection.stageCount) stage\(projection.stageCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if projection.taskCount > 0 {
                        Text("\(projection.taskCount) task\(projection.taskCount == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Spacer()
            modeBadge
        }
        .padding(.vertical, 4)
    }

    private var modeIcon: String {
        switch projection.mode {
        case .offline: return "internaldrive"
        case .online: return "cloud"
        }
    }

    private var modeColor: Color {
        switch projection.mode {
        case .offline: return .secondary
        case .online: return .blue
        }
    }

    private var modeBadge: some View {
        Text(projection.mode == .offline ? "Local" : "Online")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule().fill(projection.mode == .offline
                    ? Color.secondary.opacity(0.15)
                    : Color.blue.opacity(0.15))
            )
            .foregroundStyle(projection.mode == .offline ? Color.secondary : Color.blue)
    }
}
