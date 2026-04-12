# Authority Mode Rules

Status: Accepted

## Problem / Context

The previous architecture assumed board-only authority splits and treated projects as client-owned grouping entities.

That is no longer sufficient.

Altis now needs one explicit authority model for the main product roots:

- some projects are local-only
- some projects are online-only
- boards and tasks inherit authority from their ownership chain

The system must make that distinction explicit in domain rules, UI flows, persistence, transport contracts, and backend boundaries.

## Decision

Altis adopts two authority modes:

- `offline`
- `online`

These modes have different durable sources of truth and different write paths.

There is no sync layer between them.

## Rules

### Core principles

- `Project.mode` MUST be explicit on `Project`.
- `Board.mode` MUST be explicit on `Board`.
- `Board.mode` MUST match the mode of the owning `Project`.
- A `Task` with `boardId` inherits authority from its owning `Board`.
- A `Task` without `boardId` inherits authority from its owning `Project`.
- Mode MUST NOT be inferred from current connectivity.
- Offline entities MUST use local persistence as their only durable source of truth.
- Online entities MUST use backend APIs as their only durable source of truth.
- The system MUST NOT implement outbox, reconciliation, background replay, or version-replacement sync for online entities in the current architecture.

### Offline project rules

- Offline projects MUST be readable without network access.
- Offline projects MUST accept writes locally.
- Offline projects MUST persist durable state locally.
- Offline projects MUST NOT depend on backend identifiers, remote versions, or auth state.
- Offline projects MUST NOT create API requests as part of their normal write path.
- Offline boards inside an offline project inherit local authority from that project.
- Offline tasks inherit local authority from their owning board or project.

### Online project rules

- Online projects MUST require the backend path for reads and writes.
- Online projects MUST NOT claim durable local acceptance while offline.
- When network or auth is unavailable, online projects MUST surface unavailable, blocked, or reconnect-required state.
- Online projects MAY use in-memory state or short-lived caches for UX, but those caches are not the durable product source of truth.
- Online project mutations MUST go through typed API contracts.
- Online boards inside an online project inherit backend authority from that project.
- Online tasks inherit backend authority from their owning board or project.

### Board rules

- A board MUST belong to one project.
- A board MUST use the same mode as its owning project.
- Board stages and board-scoped tasks inherit authority from their owning board.
- The app MUST NOT permit a board mode that conflicts with the selected project mode.

### Task rules

- A task MUST belong to one project.
- A task assigned to a board MUST belong to the same project as that board.
- A task without `boardId` is still authority-bound through its project.
- The app MUST NOT silently convert an online task write into a local write.

### Workspace support entity rules

- Workspace-scoped support entities such as `TaskFilter` and `BoardStagePreset` use local client persistence in the current phase.
- The app MUST NOT infer filter or preset authority from any project's mode.

### UI read-path rules

- Offline project surfaces MUST render from local typed projections.
- Online project surfaces MUST render from feature-owned online state or explicit online read models.
- UI MUST NOT render directly from raw transport payloads.
- A feature MAY support both modes, but it MUST branch by the active entity mode and use the correct authority for that entity chain.

### Write-path rules

- Offline writes MUST stay local-only.
- Online writes MUST go through online services or gateways that wrap the API module.
- UI code MUST NOT call transport clients directly.
- There MUST NOT be a hidden fallback where an online write silently becomes a local write.

### API boundary rules

- The API module serves only online projects and related online entities.
- Offline entities MUST NOT appear in backend schemas, routes, or persistence plans except as an explicitly deferred future migration topic.
- Shared transport contracts in `shared/contracts/` describe only online-project payloads.
- Workspace-scoped filters and presets are local support entities in the current phase unless a later contract states otherwise.

### Mode transition rules

- A project MUST be created as either `offline` or `online`.
- A board MUST be created inside a project and inherit that project's mode.
- The system MUST NOT silently migrate a project, board, or task between modes.
- If explicit mode conversion is ever added later, it requires a new documented architecture decision and a dedicated migration flow.

## Invariants

- No outbox.
- No durable sync intent queue.
- No version-replacement sync contract.
- No background reconciliation between offline and online state.
- Offline entities remain usable without backend access.
- Online entities remain backend-owned even if a local cache exists.

## Consequences

- The architecture is still simpler than offline-first sync, but broader than board-only authority.
- Offline work remains possible inside offline projects.
- Online collaboration remains possible inside online projects.
- Backend and client contracts become cleaner because online ownership is rooted at project scope.
- Project mode must be chosen correctly when the project is created.
- Board creation UX must adapt because board mode is constrained by project mode.

## Implementation guidance

- Keep shared task, project, board, stage, preset, and filter semantics where they are truly common.
- Split local persistence and online transport at the service boundary.
- Treat entity mode as a routing decision in feature flows.
- Keep offline persistence contracts in `shared/persistence/`.
- Keep online transport contracts in `shared/contracts/`.
- Keep backend routes and modules focused on online projects and their owned entities.
- Keep workspace-scoped filters and presets out of backend ownership until a dedicated online contract is documented.

## Anti-patterns

- MUST NOT accept an online mutation locally and promise that it will sync later.
- MUST NOT add sync metadata to offline entities as speculative future-proofing.
- MUST NOT let offline and online entities share one fake repository API that hides authority differences.
- MUST NOT expose offline entities through backend APIs.
- MUST NOT render online entities directly from raw network responses without typed feature-level mapping.

## Glossary

- `Offline project`: a project whose durable source of truth is local persistence only.
- `Online project`: a project whose durable source of truth is backend APIs only.
- `Authority mode`: explicit data-authority choice on project and board roots that governs their owned entities.
