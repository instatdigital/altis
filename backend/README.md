# Backend

Backend services for Altis live here.

## Agent Context (Canonical Docs)

Before implementation work in `backend`, load:

- `../AGENTS.md`
- this README
- `../docs/ARCHITECTURE.md`:
  - `Layer model`
  - `Default artifact placement`
  - `Global Artifact Classification Workflow`
  - relevant backend sections
- `../docs/TYPES_AND_CONTRACTS.md` only for touched entities and contracts
- `../docs/SYNC_RULES.md` when board authority or online write-path behavior is affected
- `../docs/BACKEND_ARCHITECTURE.md`
- `../docs/PROJECT_SETUP.md` when setup, commands, or tooling matter

## Current direction

- primary backend stack: NestJS
- database access: Prisma
- first service: `api-nest/`

## Architecture rule

Backend persistence models are not the shared app contract. Shared contracts belong in `shared/contracts/`.
