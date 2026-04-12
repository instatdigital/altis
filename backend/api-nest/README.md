# Altis API Nest

Canonical NestJS backend project for Altis.

## Agent Context (Canonical Docs)

Before implementation work in `backend/api-nest`, load:

- `../../AGENTS.md`
- `../README.md`
- this README
- only the canon required by the task, following `AGENTS.md#Lean context bootstrap`
- `../../docs/BACKEND_ARCHITECTURE.md` when backend module boundaries or responsibilities matter

Default extra focus:

- placement and ownership:
  - `../../docs/ARCHITECTURE.md` with `Global Artifact Classification Workflow`
- setup or commands:
  - `../../docs/PROJECT_SETUP.md`

## Stack

- NestJS
- Prisma
- TypeScript

## MVP module layout

- `src/modules/auth`
- `src/modules/projects`
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

The API project serves only online projects and related backend-owned online entities. Offline projects do not belong in this module.
