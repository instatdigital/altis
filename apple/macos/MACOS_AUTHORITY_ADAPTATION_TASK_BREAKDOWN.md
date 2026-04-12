# macOS Authority Adaptation Checklist

Canon: `AGENTS.md`, `ARCHITECTURE.md`, `TYPES_AND_CONTRACTS.md`, `SYNC_RULES.md`, `MVP_APP_STRUCTURE.md`

Rule: `Project.mode` is explicit (`offline`|`online`). `Board.mode` matches `Project.mode`. `Task` inherits authority from `Board` or `Project`. Online entities are backend-owned. Offline entities are local-only. Zero sync between them.

## 1. Domain & Persistence
- [ ] Add explicit `mode` to `Project` (macOS Swift layer).
- [ ] Ensure `Board.mode` strictly matches owning `Project.mode`.
- [ ] Ensure `Task` derives authority from ownership chain (Board -> Project).
- [ ] Reclassify SQLite persistence to offline-only. Persist `Project.mode=offline`.
- [ ] Prevent online entities from triggering durable local SQLite writes.

## 2. Transport & Contracts
- [ ] Update online gateway contracts (`shared/contracts/` -> `App/Models/Contracts/`) to include online projects.
- [ ] Add explicit typed auth contracts (session restore, HttpOnly cookie logic handling via Session).
- [ ] Map typed online read/write models to feature flows.

## 3. Navigation & UX
- [ ] Move `offline/online` mode choice from Board creation to **Project creation**.
- [ ] Keep 1 App Shell, display both offline and online projects consistently.
- [ ] Auth gate triggers ONLY when accessing `online` project flows.

## 4. Feature Flows
- [ ] Project Flow: Add online list/create via gateway. Retain offline list/create via SQLite.
- [ ] Board Flow: Board creation inherits Project mode. Online boards use gateway.
- [ ] Task Flow: Add online project-scoped & board-scoped task create/update/detail via API.
- [ ] Kanban: Add online Kanban read, drag-and-drop, and terminal actions via typed API calls.
- [ ] Auth Flow: Add app launch session restore, logout (clears session, leaves offline data), and blocked states.

## 5. Refactor & Validation
- [ ] Feature state uses project-rooted routing, NOT board-only assumptions.
- [ ] Track & cancel online tasks on context switch.
- [ ] UI components remain transport-agnostic.
- [ ] Build macOS project, fix warnings, ensure docs sync.
