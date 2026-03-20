# Altis API Nest

Canonical NestJS backend project for Altis.

## Stack

- NestJS
- Prisma
- TypeScript

## MVP module layout

- `src/modules/auth`
- `src/modules/profile`
- `src/modules/tasks`
- `src/modules/task-filters`
- `src/modules/boards`
- `src/modules/settings`
- `src/modules/realtime`
- `src/modules/health`

## Project setup expectations

- project-level `.env.example`
- ESLint config
- Prettier config
- Prisma schema
- documented local commands for lint, test, build, and migrations

## Contract rule

Do not use Prisma-generated types as shared client contracts.
