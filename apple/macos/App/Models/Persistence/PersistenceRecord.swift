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
/// Canonical specification: `shared/persistence/PersistenceRecord.swift`
/// This file is the macOS platform copy. Platform-specific record types
/// (`ProjectRecord`, `BoardRecord`, etc.) are macOS-only and live alongside
/// this file. The protocol itself is cross-platform.
protocol PersistenceRecord: Codable, Sendable {}
