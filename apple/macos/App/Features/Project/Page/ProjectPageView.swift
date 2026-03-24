import SwiftUI

/// Project list and creation surface.
///
/// Renders the `ProjectFeatureState` provided by `ProjectFeatureFlow`.
/// All user intents are emitted as `ProjectFeatureEvent` values — the view
/// never mutates data directly.
///
/// Navigation to the board list for a selected project is delegated to the
/// shell layer via `onProjectSelected`.
struct ProjectPageView: View {

    @ObservedObject var flow: ProjectFeatureFlow

    /// Called when the user selects a project. The shell layer routes to the board list.
    var onProjectSelected: ((ProjectID) -> Void)? = nil

    @State private var isShowingCreateSheet = false
    @State private var newProjectName = ""

    var body: some View {
        Group {
            if flow.state.isLoading && flow.state.projects.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if flow.state.projects.isEmpty {
                emptyState
            } else {
                projectList
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    newProjectName = ""
                    isShowingCreateSheet = true
                } label: {
                    Label("New Project", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingCreateSheet) {
            createProjectSheet
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
            flow.send(.appeared)
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        ContentUnavailableView(
            "No Projects",
            systemImage: "folder",
            description: Text("Create your first project to get started.")
        )
    }

    private var projectList: some View {
        List(flow.state.projects, id: \.projectId) { project in
            ProjectRowView(projection: project)
                .onTapGesture {
                    flow.send(.projectSelected(project.projectId))
                    onProjectSelected?(project.projectId)
                }
        }
    }

    private var createProjectSheet: some View {
        VStack(spacing: 20) {
            Text("New Project")
                .font(.headline)

            TextField("Project name", text: $newProjectName)
                .textFieldStyle(.roundedBorder)
                .onSubmit { submitCreate() }

            HStack {
                Button("Cancel", role: .cancel) {
                    isShowingCreateSheet = false
                }
                Spacer()
                Button("Create") {
                    submitCreate()
                }
                .disabled(newProjectName.trimmingCharacters(in: .whitespaces).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 300)
    }

    // MARK: - Actions

    private func submitCreate() {
        let trimmed = newProjectName.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        isShowingCreateSheet = false
        flow.send(.createProjectRequested(name: trimmed))
    }
}

// MARK: - Project row

private struct ProjectRowView: View {

    let projection: ProjectListItemProjection

    var body: some View {
        HStack {
            Image(systemName: "folder")
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(projection.name)
                    .font(.body)
                if projection.boardCount > 0 {
                    Text("\(projection.boardCount) board\(projection.boardCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
