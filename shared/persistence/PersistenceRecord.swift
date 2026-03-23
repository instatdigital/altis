import Foundation

/// Marker protocol for all SQLite-backed persistence records.
///
/// Persistence records are flat, serialisable representations of domain entities
/// suitable for direct storage in a SQLite table row. They carry no computed
/// properties and no business logic.
///
/// Naming convention: `<Entity>Record` (e.g. `ProjectRecord`, `TaskRecord`).
///
/// Relationship to domain model:
/// - Domain → Record: encode on write (via `init(from:)` or a dedicated mapper)
/// - Record → Domain: decode on read (via a `toDomain()` method)
///
/// All string identifiers map to the `rawValue` of a typed `EntityID`.
///
/// This protocol lives in `shared/persistence/` because it is a cross-platform
/// contract. Platform-specific record types (e.g. `ProjectRecord`) live in
/// the platform app directory (e.g. `apple/macos/App/Models/Persistence/`).
protocol PersistenceRecord: Codable, Sendable {}
