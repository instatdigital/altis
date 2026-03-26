# Types And Contracts

## Goal

Define the canonical global data model, relationships, and typed boundary rules for Altis.

This file is the source of truth for:

- canonical entities
- required relationships
- typed identifiers
- local model boundaries
- transport model boundaries
- UI projection boundaries

## Global typing rule

- Domain meaning MUST be defined globally before platform implementation diverges.
- Canonical entities and relationships MUST be documented here before app-local variants appear.
- UI models, local persistence models, and transport contracts MUST remain typed and explicitly separated.
- Board mode MUST be explicit on `Board` and respected by related persistence and transport boundaries.

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

### Board

Workflow grouping for tasks inside a project.

Required fields:

- `boardId`
- `workspaceId`
- `projectId`
- `mode`
- `name`
- `createdAt`
- `updatedAt`

`mode` MUST be one of:

- `offline`
- `online`

`projectId` rule:

- `projectId` is a client-owned grouping reference in the current phase.
- For online boards, `projectId` remains part of the canonical client model but is not a backend-owned entity contract unless a later decision documents that promotion.

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

`kind` MUST be one of:

- `regular`
- `terminalSuccess`
- `terminalFailure`

### BoardStagePreset

Reusable stage definition set for creating boards.

Required fields:

- `stagePresetId`
- `workspaceId`
- `name`
- `createdAt`
- `updatedAt`

### BoardStagePresetStage

Ordered stage definition inside a board stage preset.

Required fields:

- `presetStageId`
- `stagePresetId`
- `name`
- `orderIndex`
- `kind`

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

`status` SHOULD remain compatible with board workflow and terminal outcomes.

### TaskFilter

Reusable task visibility definition shared across app surfaces and widgets.

Required fields:

- `taskFilterId`
- `workspaceId`
- `name`
- `definition`
- `createdAt`
- `updatedAt`

### BoardMode

Explicit domain value that defines data authority.

Values:

- `offline`
- `online`

Rules:

- `offline` means the board and its board-owned entities are stored locally.
- `online` means the board and its board-owned entities are served through backend APIs.
- Board mode MUST NOT be inferred from connectivity.

## Required relationships

- one `Workspace` has many `Project`
- one `Workspace` has many `BoardStagePreset`
- one `Workspace` has many `TaskFilter`
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

- A `Task` with `stageId` MUST also have `boardId`.
- A `Task` assigned to a `Board` MUST belong to the same `Project` as that `Board`.
- A `BoardStage` inherits persistence and authority from its owning `Board`.
- A `Task` assigned to a `Board` inherits persistence and authority from that `Board`.
- `Project` is a client-owned grouping entity in the current phase.
- For online boards and online board-scoped tasks, `projectId` remains a client-owned grouping reference unless a later contract makes projects backend-owned.
- A `Task` without `boardId` is project-scoped and uses local client persistence in the current phase unless a later contract documents a backend-owned non-board task flow.
- An `offline` board MUST NOT depend on backend-only identifiers or sync metadata.
- An `online` board MUST NOT rely on local durable write acceptance while disconnected.
- A `Project` may contain both offline and online boards.
- A `Workspace` may contain both offline and online boards.
- `BoardStagePreset` and `TaskFilter` are workspace-scoped support entities and are not independently typed by board mode.
- `BoardStagePreset` and `TaskFilter` use local client persistence in the current phase unless a later contract explicitly promotes them to backend-owned online entities.
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
- `Persistence record`: local storage representation
- `Transport contract`: backend payload shape
- `UI projection`: read model optimized for rendering
- `Feature state`: event-driven state owned by one feature flow

Rules:

- Domain models MUST NOT be raw transport DTOs.
- UI projections MUST NOT be raw persistence records.
- Feature state MUST NOT become the de facto domain model.
- Offline persistence records MUST NOT carry fake sync or outbox fields.
- Transport contracts exist only for online boards and related online entities that are explicitly backend-owned.
- Client-owned grouping references such as `projectId` MAY remain in client models without becoming backend-owned entities.

## UI projection rule

UI-facing projections SHOULD be explicit for the first vertical slices.

Recommended projections:

- `ProjectListItemProjection`
- `BoardListItemProjection`
- `TaskListItemProjection`
- `TaskCardProjection`
- `TaskDetailProjection`
- `BoardStageColumnProjection`
- `HomePlaceholderProjection`

These are projections, not canonical entities.

## Persistence typing rule

- Offline boards MUST use explicit local persistence records.
- Online boards MAY use ephemeral caches or transport mappers, but those are not the durable source of truth.
- SQLite records on Apple platforms MUST preserve canonical identifiers and board mode explicitly.
- Workspace-scoped presets and filters use local persistence in the current phase.

## Transport typing rule

- Backend transport contracts MUST model only online boards and related backend-owned online entities.
- Offline boards MUST NOT be represented as a syncable transport entity class.
- Workspace-scoped presets and filters MUST NOT be treated as backend-owned unless that contract is documented separately.
- Client-owned grouping references such as `projectId` MUST NOT be treated as proof that `Project` is backend-owned.
- OpenAPI-first contracts remain the preferred backend-client boundary.

Required online-board transport families in the current phase:

- auth gate contract for online-board access before backend reads or writes
- board list read model for project-scoped online board discovery
- board content read model carrying ordered stages plus board-scoped tasks
- task detail read model carrying task metadata plus board ownership references
- task stage-move write model
- task terminal-action write model

Rules:

- feature flows MUST map online read models into typed UI projections before rendering
- online board writes MUST cross typed write models rather than ad hoc parameter lists
- auth-gate failure MUST surface as blocked or unavailable online state, not as a local durable fallback
