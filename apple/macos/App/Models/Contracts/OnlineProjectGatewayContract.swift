import Foundation

/// Contract for online-project transport operations.
///
/// This protocol is the cross-platform canonical client-side boundary for
/// backend communication regarding Projects.
protocol OnlineProjectGatewayContract: Sendable {
    /// Returns all online projects for the authenticated user.
    func fetchProjects() async throws -> [OnlineProjectReadModel]

    /// Creates a new online project.
    func createProject(_ request: OnlineProjectCreateWriteModel) async throws -> OnlineProjectReadModel
}

// MARK: - Online read models

/// Lightweight transport read model for an online project.
/// Maps to the API response shape natively.
struct OnlineProjectReadModel: Sendable {
    let projectId: ProjectID
    let mode: ProjectMode // Usually .online
    let name: String
    let createdAt: Date
    let updatedAt: Date
}

struct OnlineProjectCreateWriteModel: Sendable {
    let name: String
}
