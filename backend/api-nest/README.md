# Altis API Nest

Canonical NestJS backend project for Altis.

## Agent Context (Canonical Docs)

Before implementation work in `backend/api-nest`, load:

- `../../AGENTS.md`
- `../README.md`
- `../../docs/ARCHITECTURE.md`:
  - `Layer model`
  - `Default artifact placement`
  - `Global Artifact Classification Workflow`
  - relevant backend sections
- `../../docs/BACKEND_ARCHITECTURE.md`
- `../../docs/TYPES_AND_CONTRACTS.md` only for touched entities and contracts
- `../../docs/SYNC_RULES.md` when board authority or online write-path behavior is affected
- `../../docs/PROJECT_SETUP.md` when setup, commands, or tooling matter

## Stack

- NestJS
- Prisma
- TypeScript

## MVP module layout

- `src/modules/auth`
- `src/modules/profile`
- `src/modules/tasks`
- `src/modules/boards`
- `src/modules/settings`
- `src/modules/health`

## Project setup expectations

- project-level `.env.example`
- ESLint config
- Prettier config
- Prisma schema
- documented local commands for lint, test, build, and migrations

## Contract rule

Do not use Prisma-generated types as shared client contracts.

The API project serves only online boards and related backend-owned online entities. Offline boards and client-owned projects do not belong in this module.
