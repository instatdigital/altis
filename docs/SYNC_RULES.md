# Board Mode Rules

Status: Accepted

## Problem / Context

The previous architecture assumed offline-first synchronization between local state and backend state.

That approach is now explicitly out of scope. It adds too much implementation and product cost for the current phase.

Altis now needs a simpler, harder boundary:

- some boards are local-only
- some boards are online-only

The system must make that distinction explicit in board rules, UI flows, persistence, and backend contracts.

## Decision

Altis adopts two board modes:

- `offline`
- `online`

These modes have different data authorities and different write paths.

There is no sync layer between them.

## Rules

### Core principles

- Board mode MUST be explicit on `Board`.
- Board mode MUST NOT be inferred from current connectivity.
- Offline boards MUST use local persistence as their only durable source of truth.
- Online boards MUST use backend APIs as their only durable source of truth.
- The app MUST NOT implement outbox, reconciliation, background replay, or version-replacement sync for boards and tasks in the current architecture.
- Board mode governs only the board and board-owned entities.

### Offline board rules

- Offline boards MUST be readable without network access.
- Offline boards MUST accept writes locally.
- Offline boards MUST persist durable state locally.
- Offline boards MUST NOT depend on backend identifiers, remote versions, or auth state.
- Offline boards MUST NOT create API requests as part of their normal write path.
- Board-owned entities such as board stages and board-scoped tasks inherit local storage from the offline board they belong to.

### Online board rules

- Online boards MUST require the backend path for reads and writes.
- Online boards MUST NOT claim durable local acceptance while offline.
- When network or auth is unavailable, online boards MUST surface unavailable, blocked, or reconnect-required state.
- Online boards MAY use in-memory state or short-lived caches for UX, but those caches are not the durable product source of truth.
- Online board mutations MUST go through typed API contracts.
- Board-owned entities such as board stages and board-scoped tasks inherit backend authority from the online board they belong to.

### Non-board entity rules

- A task without `boardId` is outside board-mode authority and uses local client persistence in the current phase unless a later contract documents a backend-owned non-board task flow.
- Workspace-scoped support entities such as `TaskFilter` and `BoardStagePreset` use local client persistence in the current phase.
- The app MUST NOT infer filter or preset authority from any one board's mode.

### UI read-path rules

- Offline board surfaces MUST render from local typed projections.
- Online board surfaces MUST render from feature-owned online state or explicit online read models.
- UI MUST NOT render directly from raw transport payloads.
- A feature MAY support both modes, but it MUST branch by the active board's mode and use the correct authority for that board.

### Write-path rules

- Offline board writes MUST stay local-only.
- Online board writes MUST go through online services or gateways that wrap the API module.
- UI code MUST NOT call transport clients directly.
- There MUST NOT be a hidden fallback where an online write silently becomes a local write.

### API boundary rules

- The API module serves only online boards and related online entities.
- Offline boards MUST NOT appear in backend schemas, routes, or persistence plans except as an explicitly deferred future migration topic.
- Shared transport contracts in `shared/contracts/` describe only online-board payloads.
- Workspace-scoped filters and presets are local support entities in the current phase unless a later contract states otherwise.

### Mode transition rules

- A board MUST be created as either `offline` or `online`.
- The system MUST NOT silently migrate a board between modes.
- If explicit mode conversion is ever added later, it requires a new documented architecture decision and a dedicated migration flow.

## Invariants

- No outbox.
- No durable sync intent queue.
- No version-replacement sync contract.
- No background reconciliation between offline and online board state.
- Offline boards remain usable without backend access.
- Online boards remain backend-owned even if a local cache exists.

## Consequences

- The architecture is much simpler.
- Offline work remains possible, but only inside offline boards.
- Online collaboration remains possible, but only inside online boards.
- Backend and client contracts become cleaner because they no longer need to model sync metadata and reconciliation behavior.
- Board mode must be chosen correctly when the board is created.

## Implementation guidance

- Keep shared task, project, board, stage, preset, and filter semantics where they are truly common.
- Split local persistence and online transport at the service boundary.
- Treat board mode as a routing decision in feature flows.
- Keep offline-board persistence contracts in `shared/persistence/`.
- Keep online-board transport contracts in `shared/contracts/`.
- Keep backend routes and modules focused on online boards only.
- Keep workspace-scoped filters and presets out of backend ownership until a dedicated online contract is documented.

## Anti-patterns

- MUST NOT accept an online mutation locally and promise that it will sync later.
- MUST NOT add sync metadata to offline entities as speculative future-proofing.
- MUST NOT let offline and online boards share one fake repository API that hides authority differences.
- MUST NOT expose offline boards through backend APIs.
- MUST NOT render online boards directly from raw network responses without typed feature-level mapping.

## Glossary

- `Offline board`: a board whose durable source of truth is local persistence only.
- `Online board`: a board whose durable source of truth is backend APIs only.
- `Board mode`: explicit data-authority choice on `Board` that governs the board and its board-owned entities.
