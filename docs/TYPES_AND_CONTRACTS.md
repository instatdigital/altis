# Types And Contracts

## Goal

Define the canonical global data model, relationships, and typed boundary rules for the project.

This file is the source of truth for:

- canonical entities
- required relationships
- typed identifiers
- local model boundaries
- transport model boundaries
- UI projection boundaries

## Global typing rule

- Domain meaning MUST be defined globally before platform implementation diverges.
- Canonical entities and relationships MUST be documented here before agents introduce app-local variants.
- UI models, local persistence models, and transport contracts MUST remain typed and explicitly separated.
- Platform code MAY introduce local models, but those models MUST map back to the canonical entities and relationships defined here.

## Canonical entities

### Workspace

Top-level scope for reusable presets and future collaboration boundaries.

Required fields:

- `workspaceId`
- `name`
- `createdAt`
- `updatedAt`

### Project

Top-level work grouping inside a workspace.

Required fields:

- `projectId`
- `workspaceId`
- `name`
- `createdAt`
- `updatedAt`
- `syncMetadata`

### Board

Workflow grouping for tasks inside a project.

Required fields:

- `boardId`
- `workspaceId`
- `projectId`
- `name`
- `createdAt`
- `updatedAt`
- `syncMetadata`

### BoardStage

Ordered workflow stage inside a board.

Required fields:

- `stageId`
- `boardId`
- `name`
- `orderIndex`
- `kind`
- `createdAt`
- `updatedAt`
- `syncMetadata`

`kind` MUST be one of:

- `regular`
- `terminalSuccess`
- `terminalFailure`

### BoardStagePreset

Workspace-level reusable stage definition set for creating boards.

Required fields:

- `stagePresetId`
- `workspaceId`
- `name`
- `createdAt`
- `updatedAt`
- `syncMetadata`

### BoardStagePresetStage

Ordered stage definition inside a board stage preset.

Required fields:

- `presetStageId`
- `stagePresetId`
- `name`
- `orderIndex`
- `kind`

`kind` MUST use the same enum as `BoardStage`.

### Task

Canonical work item rendered in list, task detail, widgets, and kanban.

Required fields:

- `taskId`
- `workspaceId`
- `projectId`
- `boardId?`
- `stageId?`
- `title`
- `status`
- `createdAt`
- `updatedAt`
- `lastModifiedAt`
- `syncMetadata`

`status` SHOULD remain compatible with board workflow and terminal outcomes. If the task belongs to a staged board, terminal completion state MUST align with the terminal stage rather than diverging from it.

### TaskFilter

Reusable task visibility definition shared across app surfaces and widgets.

Required fields:

- `taskFilterId`
- `workspaceId`
- `name`
- `definition`
- `createdAt`
- `updatedAt`
- `syncMetadata`

### SyncMetadata

Explicit local and remote synchronization metadata.

Required fields:

- `syncState`
- `lastSyncedAt?`
- `remoteVersion?`
- `localRevision`
- `isDirty`

## Required relationships

- one `Workspace` has many `Project`
- one `Workspace` has many `BoardStagePreset`
- one `Project` belongs to one `Workspace`
- one `Project` has many `Board`
- one `Project` has many `Task`
- one `Board` belongs to one `Project`
- one `Board` has many `BoardStage`
- one `BoardStage` belongs to one `Board`
- one `BoardStagePreset` belongs to one `Workspace`
- one `BoardStagePreset` has many `BoardStagePresetStage`
- one `Task` belongs to one `Workspace`
- one `Task` belongs to one `Project`
- one `Task` MAY belong to one `Board`
- one `Task` MAY belong to one `BoardStage`
- one `TaskFilter` belongs to one `Workspace`

## Relationship constraints

- A `Board` MUST belong to the same `Workspace` as its `Project`.
- A `BoardStage` MUST belong to the same `Board` referenced by a task's `boardId` when `stageId` is present.
- A `Task` with `stageId` MUST also have `boardId`.
- A `Task` assigned to a `Board` MUST belong to the same `Project` as that `Board`.
- A `BoardStagePreset` is workspace-level and MUST NOT belong directly to one board or one project.
- Board creation from a preset MUST copy preset stages into board-local `BoardStage` entities.

## Board stage invariants

- Every staged `Board` MUST contain at least three stages.
- Every staged `Board` MUST contain exactly one `terminalSuccess` stage.
- Every staged `Board` MUST contain exactly one `terminalFailure` stage.
- A board MUST contain at least one `regular` stage.
- Terminal stages MAY be renamed.
- Terminal stages MUST NOT be deleted.
- Deleting a non-terminal stage MUST move its tasks to the first available remaining stage in board order.
- Stage order MUST be explicit and stable through `orderIndex`.
- List, task detail, and kanban projections MUST agree on the task's current stage.

## Identifier rule

- Canonical entities MUST use explicit typed identifiers at the model layer.
- Identifiers MUST NOT be represented as untyped positional values.
- Platform code MAY wrap identifiers in stronger local types, but logical identity MUST remain stable across persistence and transport boundaries.

Recommended identifier names:

- `workspaceId`
- `projectId`
- `boardId`
- `stageId`
- `stagePresetId`
- `presetStageId`
- `taskId`
- `taskFilterId`

## Model boundary rule

The project distinguishes these model classes:

- `Domain model`: canonical business entity or value object
- `Persistence record`: SQLite-facing local storage representation
- `Transport contract`: backend-facing payload shape
- `UI projection`: read model optimized for rendering
- `Feature state`: event-driven state owned by one feature flow

Rules:

- Domain models MUST NOT be raw transport DTOs.
- UI projections MUST NOT be raw persistence records.
- Feature state MUST NOT become the de facto domain model.
- Persistence records MAY carry storage and sync metadata not exposed to UI projections.
- Transport contracts MAY omit local-only fields such as outbox metadata.

## UI projection rule

UI-facing projections SHOULD be explicit for the first vertical slice.

Recommended projections:

- `ProjectListItemProjection`
- `BoardListItemProjection`
- `TaskListItemProjection`
- `TaskCardProjection`
- `TaskDetailProjection`
- `BoardStageColumnProjection`
- `HomePlaceholderProjection`

These are projections, not canonical entities.

## Sync typing rule

- Synchronization metadata MUST be represented explicitly in typed models.
- Outbox intents or pending operations MUST use explicit typed records.
- CRUD entities MAY synchronize current state plus version metadata.
- Ledger-like entities MUST use explicit operation records and confirmed-operation projections.

## Apple local model rule

- Apple local persistence uses SQLite-backed storage.
- SQLite records MUST preserve canonical identifiers and sync metadata explicitly.
- Platform-specific convenience wrappers MAY exist, but the stored schema MUST still reflect the canonical entities and relationships defined here.

## First vertical slice minimum typed set

The macOS-first vertical slice MUST at least define typed models for:

- `Workspace`
- `Project`
- `Board`
- `BoardStage`
- `BoardStagePreset`
- `BoardStagePresetStage`
- `Task`
- `SyncMetadata`

## Documentation maintenance rule

- If implementation changes entity meaning, required fields, cardinality, or invariants, update this file in the same change.
- If a new canonical entity is introduced, document it here before treating it as reusable architecture.
