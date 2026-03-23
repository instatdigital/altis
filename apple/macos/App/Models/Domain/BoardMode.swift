import Foundation

/// Storage authority discriminator for a board.
///
/// Determines where a board's data lives and which services manage it:
/// - `offline` boards are stored in local SQLite only. No backend involvement.
/// - `online` boards are fetched from and written to the backend only. No local
///   durable storage. When the network is unavailable, online boards show an
///   unavailable state rather than stale cached data.
///
/// Board-owned entities (`BoardStage`, `Task`) inherit the storage authority of
/// their owning board. They do not carry their own mode field.
enum BoardMode: String, Hashable, Codable, Sendable, CaseIterable {
    /// Board data lives in local SQLite only. Never sent to or received from the backend.
    case offline
    /// Board data lives on the backend only. No local durable storage.
    case online
}
