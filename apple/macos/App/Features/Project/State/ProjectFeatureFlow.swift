import Foundation
import _Concurrency

/// Feature flow for the Project list and creation surface.
///
/// Owns `ProjectFeatureState` and processes `ProjectFeatureEvent` values.
/// Delegates all persistence access to `ProjectDataWorker` so the flow stays
/// free of SQLite details.
///
/// Phase 4 wires the event pipeline and state structure.
/// Phase 6 implements create/load logic by injecting a real `ProjectDataWorker`.
@MainActor
final class ProjectFeatureFlow: ObservableObject {

    @Published private(set) var state = ProjectFeatureState()

    private let worker: ProjectDataWorker

    init(worker: ProjectDataWorker) {
        self.worker = worker
    }

    // MARK: - Event entry point

    func send(_ event: ProjectFeatureEvent) {
        switch event {
        case .appeared:
            loadProjects()

        case .createProjectRequested:
            // Phase 6 implementation.
            break

        case .projectSelected:
            // Navigation handled by the page/shell layer.
            break

        case .projectsLoaded(let projects):
            let items = projects.map { project in
                ProjectListItemProjection(project: project, boardCount: 0)
            }
            state.projects = items
            state.isLoading = false

        case .loadFailed(let error):
            state.isLoading = false
            state.errorMessage = error.localizedDescription
        }
    }

    // MARK: - Effects

    private func loadProjects() {
        state.isLoading = true
        _Concurrency.Task {
            do {
                let projects = try await worker.loadProjects()
                send(.projectsLoaded(projects))
            } catch {
                send(.loadFailed(error))
            }
        }
    }
}
