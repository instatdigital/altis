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

## ADR-0003: Use latest-version replacement for task sync

Status: accepted

Decision:
Store local task state with `lastModifiedAt` and treat backend sync as replacement with the latest authoritative task version.

Rationale:
This keeps the first sync model deterministic, offline-capable, and easier to reason about than field-level merge logic.

## ADR-0004: Defer calendar sync and Google authorization

Status: accepted

Decision:
Do not shape the active architecture around calendar sync or Google authorization until those features are explicitly brought into scope.

Rationale:
This reduces premature abstraction and keeps the current architecture focused on the core task, filter, sync, collaboration, and Apple ID flows.

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
Swift and TypeScript have different runtime and tooling constraints. Sharing Prisma types or backend-internal TypeScript models directly with clients creates coupling and churn. Shared transport contracts are the stable boundary; platform-native client models can be generated from or mapped to those contracts.

## ADR-0007: Use OpenAPI-first contracts at the backend-client boundary

Status: accepted

Decision:
Prefer OpenAPI-first contracts for backend-client transport definitions stored in `shared/contracts/`.

Rationale:
NestJS aligns naturally with OpenAPI tooling, and Swift clients can map or generate transport models from that contract more reliably than from backend-internal TypeScript or Prisma types.

## ADR-0008: Treat Project and Board as canonical domain entities

Status: accepted

Decision:
Add `Project` and `Board` as first-class domain entities alongside `Task`, `TaskFilter`, and sync metadata.

Rationale:
Tasks need stable grouping by project and by board. Modeling these as real domain entities keeps list mode, kanban mode, backend APIs, and future sync behavior aligned.

## ADR-0009: Treat BoardStage and BoardStagePreset as canonical workflow entities

Status: accepted

Decision:
Add `BoardStage` and `BoardStagePreset` as first-class workflow entities inside the board model. Staged boards must define ordered stages plus one terminal successful stage and one terminal unsuccessful stage. Task completion and unsuccessful closure must move the task into those explicit terminal stages.

Rationale:
Board workflow cannot remain a kanban-only presentation concern if list, task detail, and kanban must all agree on the current stage and terminal outcomes. Stage presets also need a stable reusable definition rather than per-screen ad hoc setup.

## ADR-0010: Use SQLite-backed local persistence for Apple offline-first storage

Status: accepted

Decision:
Use SQLite-backed local persistence as the default Apple client storage for offline-first behavior, local projections, outbox persistence, and sync metadata.

Rationale:
The current architecture requires durable local writes, explicit sync metadata, local projections, and predictable control over outbox and reconciliation behavior. SQLite is a safer baseline for this than a more implicit persistence layer.

## ADR-0011: Do not implement permissions for stage and preset editing in MVP

Status: accepted

Decision:
For MVP, all users may edit board stages and workspace-level board stage presets. Role-based permissions are deferred.

Rationale:
The current priority is workflow architecture and offline-first behavior, not access control. Deferring permissions reduces premature scope while keeping later authorization work explicit.

## ADR-0009: Use feature-scoped event-driven UI flows in apps

Status: accepted

Decision:
Application UI features must update through explicit event-driven state flows. Views emit events, a feature-owned state handler coordinates effects, and rendered UI reads from feature state. This is the repository-level analogue of BLoC, without locking the implementation to one framework.

Rationale:
This keeps list, kanban, task detail, sync updates, and real-time updates aligned around one canonical task state. It also gives agents and developers a stable rule for feature ownership, page structure, and where side effects are allowed to live.
