# Backend

Backend services for Altis live here.

## Agent Context (Canonical Docs)

Before implementation work in `backend`, load:

- `../AGENTS.md`
- `../docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
- `../docs/TYPES_AND_CONTRACTS.md`
- `../docs/SYNC_RULES.md`
- `../docs/DEVELOPMENT_RULES.md`
- `../docs/BACKEND_ARCHITECTURE.md`

## Current direction

- primary backend stack: NestJS
- database access: Prisma
- first service: `api-nest/`

## Architecture rule

Backend persistence models are not the shared app contract. Shared contracts belong in `shared/contracts/`.
