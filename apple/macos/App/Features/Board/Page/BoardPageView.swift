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
    /// Called when the user taps a board row, carrying the board id and mode.
    var onBoardSelected: ((BoardID, BoardMode) -> Void)?

    @State private var isShowingCreateSheet = false
    @State private var newBoardName = ""
    @State private var selectedMode: BoardMode = .offline
    @State private var selectedPresetId: BoardStagePresetID? = nil
    @State private var isShowingStageEditor = false
    @State private var newStageName = ""

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
        .sheet(isPresented: $isShowingStageEditor, onDismiss: {
            newStageName = ""
            flow.send(.stageEditorDismissed)
        }) {
            stageEditorSheet
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
            BoardRowView(
                projection: board,
                onManageStages: board.mode == .offline ? {
                    newStageName = ""
                    flow.send(.stageEditorRequested(board))
                    isShowingStageEditor = true
                } : nil
            )
            .onTapGesture {
                flow.send(.boardSelected(board.boardId))
                onBoardSelected?(board.boardId, board.mode)
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

    private var stageEditorSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let board = flow.state.stageEditorBoard {
                Text("Manage Stages")
                    .font(.headline)
                Text(board.name)
                    .font(.title3)

                if flow.state.isLoadingStages {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    stageEditorList
                }

                Divider()

                HStack {
                    TextField("New stage name", text: $newStageName)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { submitAddStage(for: board.boardId) }
                    Button("Add Stage") {
                        submitAddStage(for: board.boardId)
                    }
                    .disabled(
                        newStageName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || flow.state.isMutatingStages
                    )
                }
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 420)
    }

    private var stageEditorList: some View {
        List {
            ForEach(Array(flow.state.boardStages.enumerated()), id: \.element.stageId) { index, stage in
                BoardStageEditorRow(
                    stage: stage,
                    index: index,
                    totalCount: flow.state.boardStages.count,
                    isMutating: flow.state.isMutatingStages,
                    onRename: { newName in
                        guard let boardId = flow.state.stageEditorBoard?.boardId else { return }
                        flow.send(.renameStageRequested(boardId: boardId, stageId: stage.stageId, name: newName))
                    },
                    onMoveUp: {
                        guard let boardId = flow.state.stageEditorBoard?.boardId else { return }
                        flow.send(.moveStageRequested(boardId: boardId, stageId: stage.stageId, destinationIndex: index - 1))
                    },
                    onMoveDown: {
                        guard let boardId = flow.state.stageEditorBoard?.boardId else { return }
                        flow.send(.moveStageRequested(boardId: boardId, stageId: stage.stageId, destinationIndex: index + 1))
                    },
                    onDelete: {
                        guard let boardId = flow.state.stageEditorBoard?.boardId else { return }
                        flow.send(.deleteStageRequested(boardId: boardId, stageId: stage.stageId))
                    }
                )
            }
        }
        .listStyle(.inset)
    }

    private func submitAddStage(for boardId: BoardID) {
        let trimmed = newStageName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        newStageName = ""
        flow.send(.addStageRequested(boardId: boardId, name: trimmed))
    }
}

// MARK: - Board row

private struct BoardRowView: View {

    let projection: BoardListItemProjection
    let onManageStages: (() -> Void)?

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
            if let onManageStages {
                Button("Stages", action: onManageStages)
                    .buttonStyle(.borderless)
            }
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

private struct BoardStageEditorRow: View {

    let stage: BoardStage
    let index: Int
    let totalCount: Int
    let isMutating: Bool
    let onRename: (String) -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onDelete: () -> Void

    @State private var draftName: String

    init(
        stage: BoardStage,
        index: Int,
        totalCount: Int,
        isMutating: Bool,
        onRename: @escaping (String) -> Void,
        onMoveUp: @escaping () -> Void,
        onMoveDown: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.stage = stage
        self.index = index
        self.totalCount = totalCount
        self.isMutating = isMutating
        self.onRename = onRename
        self.onMoveUp = onMoveUp
        self.onMoveDown = onMoveDown
        self.onDelete = onDelete
        _draftName = State(initialValue: stage.name)
    }

    var body: some View {
        HStack(spacing: 12) {
            TextField("Stage name", text: $draftName)
                .textFieldStyle(.roundedBorder)
                .disabled(isMutating)
                .onSubmit { submitRename() }

            Text(kindLabel)
                .font(.caption)
                .foregroundStyle(kindColor)

            Button {
                submitRename()
            } label: {
                Image(systemName: "checkmark")
            }
            .buttonStyle(.borderless)
            .disabled(isMutating || draftName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || draftName == stage.name)

            Button {
                onMoveUp()
            } label: {
                Image(systemName: "arrow.up")
            }
            .buttonStyle(.borderless)
            .disabled(isMutating || index == 0)

            Button {
                onMoveDown()
            } label: {
                Image(systemName: "arrow.down")
            }
            .buttonStyle(.borderless)
            .disabled(isMutating || index == totalCount - 1)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(isMutating || stage.isTerminal)
        }
        .onChange(of: stage.name) { _, newValue in
            draftName = newValue
        }
    }

    private var kindLabel: String {
        switch stage.kind {
        case .regular:
            return "Regular"
        case .terminalSuccess:
            return "Terminal Success"
        case .terminalFailure:
            return "Terminal Failure"
        }
    }

    private var kindColor: Color {
        switch stage.kind {
        case .regular:
            return .secondary
        case .terminalSuccess:
            return .green
        case .terminalFailure:
            return .red
        }
    }

    private func submitRename() {
        let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != stage.name else { return }
        onRename(trimmed)
    }
}
