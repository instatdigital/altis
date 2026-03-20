# Types and Contracts

## Short answer

Yes, the product should have a shared contract layer.

No, it should not try to share one literal runtime type system across Swift clients and the NestJS backend.

The explicit architectural choice is:

- shared domain meaning
- shared transport contracts
- platform-native implementation models

## Recommended split

### `shared/domain`

Conceptual domain models and rules:

- task concepts
- project concepts
- board concepts
- task status concepts
- task filter concepts
- board grouping concepts
- sync metadata concepts

These represent business meaning, not backend ORM output.

### `shared/contracts`

Transport-facing contracts:

- request payloads
- response payloads
- event payloads
- auth payloads
- error shapes
- project payloads
- board payloads
- task payloads that reference `projectId` and optional `boardId`

This is the correct cross-platform boundary.

### Backend internal types

NestJS and Prisma can have backend-internal DTOs, entities, and persistence models.

### Client-native types

Swift apps can have client-native models optimized for UI and local storage, as long as they map cleanly to the shared contracts and domain meaning.

## What not to do

- do not expose Prisma-generated types as the app-wide source of truth
- do not force Swift to mirror backend internals one-to-one
- do not mix transport DTOs with local persistence models
- do not use one backend-defined TypeScript object model as the direct source for Swift runtime models

## Why

Trying to keep one literal type store across Swift and NestJS usually becomes painful because:

- toolchains are different
- runtime needs are different
- local storage models diverge from transport payloads
- backend persistence models change for reasons unrelated to clients

## Recommended direction

Use a contract-first boundary.

Good options to evaluate:

- OpenAPI-first contracts
- JSON Schema for transport payloads

Current architectural direction:

- prefer OpenAPI-first contracts for backend-client boundaries

Then:

- generate TypeScript types where useful for backend and tooling
- generate or map Swift client models from the contract layer
- keep Prisma behind the backend boundary

## Canonical domain entities to preserve across contracts

- `Task`
- `Project`
- `Board`
- `TaskFilter`
- `SyncMetadata`

## Relationship guidance

- a task belongs to one project
- a task may belong to one board
- a board belongs to one project
- list and kanban views are projections over tasks within project and board context
