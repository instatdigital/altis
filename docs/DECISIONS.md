# Decisions

## ADR-0001: Bootstrap repository by platform and shared layers

Status: accepted

Decision:
Use a top-level layered monorepo structure:

- `common/assets`
- `shared`
- `apple/shared`
- `apple/ios`
- `apple/macos`
- `android`
- `windows`
- `.github/workflows`
- `tooling`
- `docs`

Rationale:
This keeps platform boundaries obvious while preserving a single place for shared logic and assets.

## ADR-0002: Use one canonical task model across list, kanban, and widgets

Status: accepted

Decision:
Represent tasks once in the shared domain and let list, kanban, and widgets act as projections over that model.

Rationale:
This avoids parallel logic for the same product state and keeps widget filtering central to the architecture.

## ADR-0003: Split boards into explicit offline and online modes

Status: accepted

Decision:
Boards are created as either `offline` or `online`.

- `offline` boards are stored and edited only locally
- `online` boards are loaded and edited only through backend APIs
- no offline-online sync layer is part of the active architecture

Rationale:
This removes the cost and complexity of offline-first sync, outbox handling, reconciliation, and version-replacement logic while preserving both local-only and server-backed product paths.

## ADR-0004: Defer offline-online sync, calendar sync, and Google authorization

Status: accepted

Decision:
Do not shape the active architecture around offline-online sync, calendar sync, or Google authorization until those features are explicitly brought into scope.

Rationale:
This reduces premature abstraction and keeps the current architecture focused on explicit board mode boundaries.

## ADR-0005: Add NestJS and Prisma as the backend stack

Status: accepted

Decision:
Place backend services in `backend/` and use NestJS for application structure with Prisma as the database access layer.

Rationale:
This provides a modular backend architecture with a mature TypeScript ecosystem while keeping database concerns explicit and maintainable.

## ADR-0006: Share contracts, not runtime types, across backend and clients

Status: accepted

Decision:
Do not attempt to force one shared runtime type layer across Swift clients and the NestJS backend. Instead, keep shared domain concepts in repository documentation and shared contract artifacts in `shared/contracts/`.

Rationale:
Swift and TypeScript have different runtime and tooling constraints. Shared transport contracts are the stable boundary.

## ADR-0007: Use OpenAPI-first contracts at the backend-client boundary

Status: accepted

Decision:
Prefer OpenAPI-first contracts for backend-client transport definitions stored in `shared/contracts/`.

Rationale:
NestJS aligns naturally with OpenAPI tooling, and Swift clients can map or generate transport models from that contract more reliably than from backend-internal TypeScript or Prisma types.

## ADR-0008: Treat Project and Board as canonical domain entities

Status: accepted

Decision:
Keep `Project` and `Board` as first-class domain entities alongside `Task` and `TaskFilter`, and make board mode explicit on `Board`.

Rationale:
Tasks need stable grouping by project and by board. Board mode changes product behavior enough that it must be modeled explicitly, but it should not force separate mode flags onto every surrounding entity.

## ADR-0009: Treat BoardStage and BoardStagePreset as canonical workflow entities

Status: accepted

Decision:
Keep `BoardStage` and `BoardStagePreset` as first-class workflow entities inside the board model. Staged boards must define ordered stages plus one terminal successful stage and one terminal unsuccessful stage.

Rationale:
Board workflow cannot remain a kanban-only presentation concern if list, task detail, and kanban must all agree on the current stage and terminal outcomes.

## ADR-0010: Keep workspace-scoped presets and filters client-owned in the current phase

Status: accepted

Decision:
Keep `BoardStagePreset` and `TaskFilter` as workspace-scoped client-owned entities in the current phase. They are not typed by board mode and are not backend-owned by default.

Rationale:
Board mode should govern boards and board-owned entities only. Promoting presets or filters into backend-owned online entities would add a second authority split that is not required by the current product decision.

## ADR-0011: Keep projects client-owned in the current phase

Status: accepted

Decision:
Keep `Project` as a client-owned grouping entity in the current phase even when it contains online boards.

Rationale:
Board mode governs boards and board-owned entities only. Making `Project` backend-owned while one project may contain both offline and online boards would reintroduce a second authority split without a documented need.

Implication:
`projectId` remains a client-owned grouping reference in canonical client models unless a later decision explicitly promotes projects into backend-owned online entities.

## ADR-0012: Use SQLite-backed local persistence for offline Apple boards

Status: accepted

Decision:
Use SQLite-backed local persistence as the default Apple client storage for offline boards.

Rationale:
Offline boards still require durable local storage, but that storage no longer needs sync metadata, outbox behavior, or reconciliation infrastructure.

## ADR-0013: Do not implement permissions for stage and preset editing in MVP

Status: accepted

Decision:
For MVP, all users may edit board stages and workspace-level board stage presets. Role-based permissions are deferred.

Rationale:
The current priority is workflow architecture and board mode separation, not access control.

## ADR-0014: Use feature-scoped event-driven UI flows in apps

Status: accepted

Decision:
Application UI features must update through explicit event-driven state flows. Views emit events, a feature-owned state handler coordinates effects, and rendered UI reads from feature state.

Rationale:
This keeps list, kanban, task detail, offline persistence, and online API flows aligned around one architectural rule for state ownership.
