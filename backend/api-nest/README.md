# Altis API Nest

Canonical NestJS backend project for Altis.

## Agent Context (Canonical Docs)

Before implementation work in `backend/api-nest`, load:

- `../../AGENTS.md`
- `../../docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
- `../../docs/BACKEND_ARCHITECTURE.md`
- `../../docs/TYPES_AND_CONTRACTS.md`
- `../../docs/SYNC_RULES.md`
- `../../docs/DEVELOPMENT_RULES.md`
- `../README.md`

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
