# Backend MVP execution checklist

Canon: `AGENTS.md`, docs (`ARCHITECTURE.md`, `TYPES_AND_CONTRACTS.md`, `BACKEND_ARCHITECTURE.md`, `SYNC_RULES.md`)

Rule: Projects define authority. `online` projects are backend-owned. `Board` and `Task` inherit. No sync fallback.

## 0. Bootstrap
- [x] Init NestJS (`auth`, `projects`, `boards`, `tasks`, `profile`, `settings`)
- [x] Global config, request validation, error envelope, logging, OpenAPI, health endpoints.

## 1. DB & Prisma
- [x] Init Prisma (User, Session, Project, Board, BoardStage, Task) — User + Session done; rest in Tasks 3-5
- [x] Add unique constraints & relations (Ownership chain)
- [x] Add `mode` explicit fields (must be `online` in backend context)
- [x] Generate client, add first migration

## 2. Auth MVP (Best Practice)
- [x] Store `Session` records linked to `User`
- [x] Implement JWT: Do NOT send tokens in response body.
- [x] Use `Set-Cookie: HttpOnly; Secure; SameSite=Strict` for session payload & refresh
- [x] `POST /auth/apple/exchange` or dummy MVP verify -> Creates session -> sets HTTP-only cookie
- [x] `POST /auth/logout` -> clears cookie, revokes DB session
- [x] `GET /auth/session` -> returns `user` context using auth cookie
- [x] Add CORS/CSRF protections.

## 3. Projects
- [x] Define shared canonical transport contracts (no Prisma leakage)
- [x] `GET /projects` (list `online` only)
- [x] `POST /projects` (creates project, MUST set `mode=online`)
- [x] Implement ownership boundary (user-scoped logic).

## 4. Boards & Stages
- [x] `GET /projects/:id/boards`, `POST /projects/:id/boards` (boards inherit `online` mode)
- [x] Stage endpoints (create, rename, reorder, delete non-terminal)
- [x] Enforce invariates: min 3 stages, 1 success, 1 failure.

## 5. Tasks
- [x] `POST /projects/:id/tasks` (project-scoped)
- [x] `POST /boards/:id/tasks` (board-scoped)
- [x] `PUT /tasks/:id`, `POST /tasks/:id/move`, `POST /tasks/:id/complete`, `POST /tasks/:id/fail`

## 6. Wrap Up
- [x] Profile `GET /profile/me`
- [x] Global error handling (unavailable, forbidden, not-found)
- [x] Integration tests across Auth, Projects, Boards, Tasks
- [x] Commit & sync canonical contracts to `shared/contracts`
