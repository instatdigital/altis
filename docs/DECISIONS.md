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
