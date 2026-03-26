# Altis Agent Instructions

Use this file as the routing layer for the monorepo. Keep global rules here and keep canonical product or architecture details in `docs/`.

## Repository purpose

Altis is a multi-platform task manager monorepo split between shared business logic, Apple shared code, platform app shells, backend services, common assets, and tooling.

## Working copy rule

- Prefer the real project path over autosave or mirror copies.
- Verify the active root before writing when duplicate copies exist.

## Product invariants

- One canonical task model powers list, kanban, task detail, and widgets.
- Widget filters are first-class product entities.
- `Board.mode` is explicit: `offline` or `online`.
- Offline boards are local-only.
- Online boards are backend-only.
- There is no sync, outbox, reconciliation, or hidden local fallback for online boards.
- Collaboration, real-time delivery, and Apple ID auth are online-only directions for now.
- Calendar sync and Google auth stay deferred unless explicitly requested.

## Lean context bootstrap

Always load:

- `AGENTS.md`

For scoped work, also load the nearest platform or layer README, then load only the canon required by the task:

- placement, ownership, layers:
  - `docs/ARCHITECTURE.md`: `Layer model`, `Default artifact placement`, `Global Artifact Classification Workflow`, plus the relevant platform or feature section
- entities, identifiers, typed boundaries:
  - `docs/TYPES_AND_CONTRACTS.md`: touched entities and relevant boundary rules only
- board authority, persistence, transport, availability:
  - `docs/SYNC_RULES.md`
- screens, navigation, shells, UX flow responsibilities:
  - `docs/MVP_APP_STRUCTURE.md`: relevant sections only
- build, setup, commands, tooling:
  - `docs/PROJECT_SETUP.md`
- implementation checklist and validation closeout:
  - `docs/DEVELOPMENT_RULES.md` only when needed

Do not preload unrelated docs.

## Artifact placement rule

Before creating or moving a file:

1. Run `Global Artifact Classification Workflow` from `docs/ARCHITECTURE.md`.
2. Start with the narrowest valid ownership boundary.
3. Promote to a wider layer only with a real second consumer.

Canonical destinations:

- shared domain: `shared/domain/`
- shared application orchestration: `shared/application/`
- shared persistence contracts: `shared/persistence/`
- transport contracts: `shared/contracts/`
- Apple-only shared code: `apple/shared/`
- platform app code: platform directory
- backend modules and infra: `backend/`
- assets: `common/assets/`
- automation and CI: `tooling/`
- docs: `docs/`

Apple contract mirror rule:

- `shared/contracts/` is the canonical contract spec.
- Apple app targets cannot consume it directly.
- Matching app-local copies in `App/Models/Contracts/` must stay structurally in sync in the same change.

## Architecture and UI rules

- Prefer minimal, additive changes.
- Keep shared logic out of platform UI layers.
- Keep platform-specific UI and integrations out of `shared/`.
- Prefer native platform components for user-facing work.
- Pages compose UI from typed projections or feature state.
- Components render typed input and emit typed intents.
- UI code must not call transport clients directly.
- Feature flows own event handling, state transitions, and effects.
- Feature flows MUST track and explicitly cancel background tasks on context change or teardown to prevent stale SQLite calls.
- Initial load and later updates must enter the same explicit event pipeline for the active mode.

## Documentation and validation

- Update the relevant canonical doc in the same change when structure, types, UX flow, or sync behavior changes.
- Treat undocumented structural, UX, or sync changes as incomplete work.
- After implementation, run the strongest relevant build, test, lint, or diagnostics step available.
- If full validation is not possible, run the closest available check and report the limitation.

## Current phase

Priority is still bootstrap: stabilize structure, keep offline and online board boundaries explicit, continue the macOS-first vertical slice, and avoid premature implementation detail.
