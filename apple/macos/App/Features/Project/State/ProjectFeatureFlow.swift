import Foundation
import _Concurrency

/// Feature flow for the Project list and creation surface.
///
/// Owns `ProjectFeatureState` and processes `ProjectFeatureEvent` values.
/// Delegates all persistence access to `ProjectDataWorker` so the flow stays
/// free of SQLite details.
@MainActor
final class ProjectFeatureFlow: ObservableObject {

    @Published private(set) var state = ProjectFeatureState()

    private let worker: ProjectDataWorker
    private let workspaceId: WorkspaceID

    init(worker: ProjectDataWorker, workspaceId: WorkspaceID) {
        self.worker = worker
        self.workspaceId = workspaceId
    }

    // MARK: - Event entry point

    func send(_ event: ProjectFeatureEvent) {
        switch event {
        case .appeared:
            loadProjects()

        case .createProjectRequested(let name):
            createProject(name: name)

        case .projectSelected:
            // Navigation handled by the page/shell layer.
            break

        case .projectsLoaded(let projections):
            // Projections arrive pre-computed from the store (including boardCount).
            // Assign directly — do not rebuild from domain entities.
            state.projects = projections
            state.isLoading = false

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription

        case .errorAcknowledged:
            state.errorMessage = nil
        }
    }

    // MARK: - Effects

    private func loadProjects() {
        state.isLoading = true
        state.errorMessage = nil
        _Concurrency.Task {
            do {
                let projections = try await worker.loadProjects()
                send(.projectsLoaded(projections))
            } catch {
                send(.loadFailed(error))
            }
        }
    }

    private func createProject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        state.isLoading = true
        state.errorMessage = nil
        _Concurrency.Task {
            do {
                _ = try await worker.createProject(name: trimmed, workspaceId: workspaceId)
                // Reload the list after creation so the projection is fresh.
                let projections = try await worker.loadProjects()
                send(.projectsLoaded(projections))
            } catch {
                send(.loadFailed(error))
            }
        }
    }
}
