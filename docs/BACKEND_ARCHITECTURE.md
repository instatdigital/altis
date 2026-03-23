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
- `boards`
- `settings`
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

- task CRUD for online boards only
- task detail payloads
- task links to board and stage identities
- optional client grouping references may be echoed or mapped, but they do not make those groupings backend-owned by default

### `boards`

- online board CRUD
- board stage CRUD
- board-oriented task responses

### `settings`

- server-backed user settings when required

### `health`

- service health and readiness endpoints

## Boundary rule

- Prisma models are backend internals.
- Shared contracts must remain transport-oriented and must not expose Prisma-generated types directly.
- Backend APIs represent only online boards and related backend-owned online entities.
- Offline boards do not belong to the backend architecture in the current phase.
- Projects are not backend-owned by default in the current phase.
- Workspace-scoped filters and stage presets are not backend-owned by default in the current phase.
- Client grouping references such as `projectId` do not by themselves create backend ownership.
