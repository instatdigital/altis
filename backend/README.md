# Backend

Backend services for Altis live here.

## Agent Context (Canonical Docs)

Before implementation work in `backend`, load:

- `../AGENTS.md`
- this README
- only the canon required by the task, following `AGENTS.md#Lean context bootstrap`
- `../docs/BACKEND_ARCHITECTURE.md` when backend module boundaries or responsibilities matter

Default extra focus:

- placement and ownership:
  - `../docs/ARCHITECTURE.md` with `Global Artifact Classification Workflow`
- setup or commands:
  - `../docs/PROJECT_SETUP.md`

## Current direction

- primary backend stack: NestJS
- database access: Prisma
- first service: `api-nest/`
- backend ownership is limited to online boards and related backend-owned online entities

## Architecture rule

Backend persistence models are not the shared app contract. Shared contracts belong in `shared/contracts/`.
