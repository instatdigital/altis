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
    private var activeTasks: [_Concurrency.Task<Void, Never>] = []

    init(worker: ProjectDataWorker, workspaceId: WorkspaceID) {
        self.worker = worker
        self.workspaceId = workspaceId
    }

    deinit {
        for task in activeTasks { task.cancel() }
    }

    // MARK: - Event entry point

    func send(_ event: ProjectFeatureEvent) {
        switch event {
        case .appeared:
            cancelActiveTasks()
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

    // MARK: - Task lifecycle

    func cancelActiveTasks() {
        for task in activeTasks { task.cancel() }
        activeTasks.removeAll()
    }

    func cancelAndDrainActiveTasks() async {
        let snapshot = activeTasks
        activeTasks.removeAll()
        for task in snapshot {
            task.cancel()
            _ = await task.result
        }
    }

    @discardableResult
    private func spawnTask(_ body: @escaping () async -> Void) -> _Concurrency.Task<Void, Never> {
        let task = _Concurrency.Task { await body() }
        activeTasks.append(task)
        _Concurrency.Task {
            _ = await task.result
            self.activeTasks.removeAll(where: { $0 == task })
        }
        return task
    }

    // MARK: - Effects

    private func loadProjects() {
        state.isLoading = true
        state.errorMessage = nil
        spawnTask {
            do {
                let projections = try await self.worker.loadProjects()
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.projectsLoaded(projections))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.loadFailed(error))
            }
        }
    }

    private func createProject(name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        state.isLoading = true
        state.errorMessage = nil
        spawnTask {
            do {
                _ = try await self.worker.createProject(name: trimmed, workspaceId: self.workspaceId)
                guard !_Concurrency.Task.isCancelled else { return }
                // Reload the list after creation so the projection is fresh.
                let projections = try await self.worker.loadProjects()
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.projectsLoaded(projections))
            } catch {
                guard !_Concurrency.Task.isCancelled else { return }
                self.send(.loadFailed(error))
            }
        }
    }
}
