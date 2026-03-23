import Foundation

/// Workspace-level reusable stage definition set used when creating new boards.
///
/// Presets are not live links. Board creation copies preset stages into
/// board-local `BoardStage` entities rather than referencing the preset.
struct BoardStagePreset: Hashable, Codable, Sendable {

    /// Stable typed identifier for this preset.
    let stagePresetId: BoardStagePresetID

    /// Workspace this preset belongs to.
    let workspaceId: WorkspaceID

    /// Display name shown in the board creation flow.
    var name: String

    /// UTC timestamp of when this preset was created.
    let createdAt: Date

    /// UTC timestamp of the most recent change to this preset.
    var updatedAt: Date

    init(
        stagePresetId: BoardStagePresetID = BoardStagePresetID(),
        workspaceId: WorkspaceID,
        name: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.stagePresetId = stagePresetId
        self.workspaceId = workspaceId
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - BoardStagePresetStage

/// Ordered stage definition inside a board stage preset.
///
/// Uses the same `BoardStageKind` enum as `BoardStage` so preset stages and
/// live board stages share identical semantic constraints.
struct BoardStagePresetStage: Hashable, Codable, Sendable {

    /// Stable typed identifier for this preset stage.
    let presetStageId: BoardStagePresetStageID

    /// Preset this stage belongs to.
    let stagePresetId: BoardStagePresetID

    /// Display name used as the default name when copying into a board.
    var name: String

    /// Zero-based sort position within the preset. Must be stable and unique per preset.
    var orderIndex: Int

    /// Semantic kind. Must satisfy the same board-level invariants when copied.
    var kind: BoardStageKind

    init(
        presetStageId: BoardStagePresetStageID = BoardStagePresetStageID(),
        stagePresetId: BoardStagePresetID,
        name: String,
        orderIndex: Int,
        kind: BoardStageKind
    ) {
        self.presetStageId = presetStageId
        self.stagePresetId = stagePresetId
        self.name = name
        self.orderIndex = orderIndex
        self.kind = kind
    }
}
