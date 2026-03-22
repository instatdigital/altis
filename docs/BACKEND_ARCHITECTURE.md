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
- task sync
- task detail payloads
- task links to project, board, and stage identities

### `task-filters`

- persisted filter definitions
- widget-compatible filter payloads

### `projects`

- project CRUD
- project scoping for task queries

### `boards`

- board CRUD
- board stage CRUD
- board stage preset support
- board-oriented task responses

### `settings`

- server-backed user settings when required

### `realtime`

- live invalidation or live update entry
- collaboration event delivery

### `health`

- service health and readiness endpoints

## Boundary rule

- Prisma models are backend internals.
- Shared contracts must remain transport-oriented and must not expose Prisma-generated types directly.
