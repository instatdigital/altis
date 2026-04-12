# Backend Architecture

## Stack

- NestJS
- Prisma

## Canonical backend project

The first backend project lives in `backend/api-nest/`.

## MVP backend modules

- `auth`
- `projects`
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

- task CRUD for online projects only
- task detail payloads
- task links to board and stage identities
- task ownership is backend-owned when its parent project or board is online

### `projects`

- online project CRUD
- project is the root authority entity; an online project is strictly backend-owned
- project membership and ownership boundaries
- project-scoped list responses and entry points

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
- Backend APIs represent only online projects and related backend-owned online entities.
- Offline boards do not belong to the backend architecture in the current phase.
- Offline projects do not belong to the backend architecture in the current phase.
- Workspace-scoped filters and stage presets are not backend-owned by default in the current phase.
