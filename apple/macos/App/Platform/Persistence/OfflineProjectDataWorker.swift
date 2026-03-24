import Foundation

/// Concrete `ProjectDataWorker` backed by `OfflineLocalStore`.
///
/// Reads project list projections and creates new projects using the offline
/// SQLite store. The feature flow never touches the store directly — all
/// persistence access is encapsulated here.
///
/// Rules (from `docs/ARCHITECTURE.md`):
/// - Data workers MUST encapsulate data access behind typed interfaces.
/// - UI-facing code MUST NOT call persistence or transport directly.
struct OfflineProjectDataWorker: ProjectDataWorker {

    private let store: OfflineLocalStore
    private let workspaceId: WorkspaceID

    init(store: OfflineLocalStore, workspaceId: WorkspaceID) {
        self.store = store
        self.workspaceId = workspaceId
    }

    // MARK: - ProjectDataWorker

    func loadProjects() async throws -> [ProjectListItemProjection] {
        // Delegate directly to the store's projection-read method so that
        // store-computed fields (e.g. boardCount) reach the feature flow intact.
        try await store.fetchProjectListItems(workspaceId: workspaceId)
    }

    func createProject(name: String, workspaceId: WorkspaceID) async throws -> Project {
        let now = Date()
        let project = Project(
            projectId: ProjectID(),
            workspaceId: workspaceId,
            name: name,
            createdAt: now,
            updatedAt: now
        )
        try await store.createProject(project)
        return project
    }
}
