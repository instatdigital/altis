import Foundation

/// Typed phantom-wrapped identifier for canonical domain entities.
///
/// Uses a phantom `Tag` type to prevent accidental cross-entity identity comparisons
/// while keeping the underlying storage as a UUID string compatible with persistence
/// and transport boundaries.
///
/// Usage:
///   typealias WorkspaceID = EntityID<WorkspaceTag>
///   let id = WorkspaceID()                // new random ID
///   let id = WorkspaceID(rawValue: "...") // from stored string
struct EntityID<Tag>: RawRepresentable, Hashable, Codable, Sendable, CustomStringConvertible {

    let rawValue: String

    /// Creates a new random identifier backed by a UUID.
    init() {
        self.rawValue = UUID().uuidString
    }

    /// Wraps an existing raw string value (e.g. from persistence or transport).
    init(rawValue: String) {
        self.rawValue = rawValue
    }

    var description: String { rawValue }
}

// MARK: - Phantom tags

enum WorkspaceTag {}
enum ProjectTag {}
enum BoardTag {}
enum BoardStageTag {}
enum BoardStagePresetTag {}
enum BoardStagePresetStageTag {}
enum TaskTag {}
enum TaskFilterTag {}

// MARK: - Canonical type aliases

typealias WorkspaceID           = EntityID<WorkspaceTag>
typealias ProjectID             = EntityID<ProjectTag>
typealias BoardID               = EntityID<BoardTag>
typealias BoardStageID          = EntityID<BoardStageTag>
typealias BoardStagePresetID    = EntityID<BoardStagePresetTag>
typealias BoardStagePresetStageID = EntityID<BoardStagePresetStageTag>
typealias TaskID                = EntityID<TaskTag>
typealias TaskFilterID          = EntityID<TaskFilterTag>
