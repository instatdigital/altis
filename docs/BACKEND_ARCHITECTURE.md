# Backend Architecture

## Stack

- NestJS
- Prisma

## Canonical backend project

The first backend project lives in `backend/api-nest/`.

## MVP backend modules

- `auth`
- `profile`
- `tasks`
- `task-filters`
- `projects`
- `boards`
- `settings`
- `realtime`
- `health`

## Responsibilities

### `auth`

- online identity
- session or token validation
- Apple ID integration handoff from client apps

### `profile`

- user profile data
- account preferences that are server-backed

### `tasks`

- task CRUD
- latest-version task sync
- task detail payloads
- task links to project and board identities

### `task-filters`

- persisted filter definitions
- widget-compatible filter payloads

### `projects`

- project CRUD
- project scoping for task queries
- project-level metadata

### `boards`

- board grouping logic and board-oriented task responses
- board CRUD
- board membership or ownership within project scope

### `settings`

- server-backed user settings when required

### `realtime`

- live task updates
- collaboration event delivery

### `health`

- service health and readiness endpoints

## Prisma boundary

Prisma is a backend persistence tool, not the shared type system for the product. Prisma models may inform backend implementation, but client-facing contracts should remain transport-oriented and live outside backend internals.

## Validation expectations

The backend project should eventually expose clear commands for:

- lint
- test
- build
- Prisma generate
- Prisma migrate
