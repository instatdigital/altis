# Altis Agent Instructions

This file is the default agent context for the `altis` monorepo.

Use it as the routing layer. Canonical product and architecture details live in the docs referenced here and should not be duplicated in platform README files.

## Repository purpose

Altis is a multi-platform task manager monorepo with explicit separation between:

- shared business logic
- Apple shared code
- platform app shells
- backend services
- common visual assets
- tooling and CI

## Working copy rule

- Treat the real project path as the source of truth when a temporary mirror or autosave copy also exists.
- Verify the active project root before writing when there is any sign of duplicate copies.
- Do not leave agreed changes only inside `Autosave Information` or another temporary mirror.

## Product invariants

- One canonical task model powers list, kanban, task detail, and widgets.
- Widget filters are first-class product entities, not view-only state.
- `Board.mode` is explicit: `offline` or `online`.
- Offline boards are local-only.
- Online boards are backend-only.
- There is no sync, outbox, reconciliation, or hidden local fallback for online boards.
- Collaboration, real-time delivery, and Apple ID auth are active directions only for online capabilities.
- Calendar sync and Google auth remain deferred unless explicitly requested.

## Canonical docs

- `docs/ARCHITECTURE.md`: repository, layers, placement rules, component taxonomy, event-flow model, artifact classification workflow
- `docs/TYPES_AND_CONTRACTS.md`: entities, relations, typed boundary rules
- `docs/SYNC_RULES.md`: offline vs online authority and write-path rules
- `docs/MVP_APP_STRUCTURE.md`: UX architecture, sections, shells, navigation, flow responsibilities
- `docs/PROJECT_SETUP.md`: environment, tooling, project-level commands
- `docs/DEVELOPMENT_RULES.md`: implementation and validation checklist

## Lean context bootstrap

Read only the docs and sections needed for the current task.

Always load:

- `AGENTS.md`

For platform-scoped work in `apple/ios`, `apple/macos`, `android`, `windows`, or `backend`:

- nearest platform README
- `docs/ARCHITECTURE.md`:
  - `Layer model`
  - `Default artifact placement`
  - `Global Artifact Classification Workflow`
  - relevant platform or feature sections
- `docs/TYPES_AND_CONTRACTS.md`:
  - only entities and boundary rules touched by the change
- `docs/SYNC_RULES.md`:
  - always when board, task, persistence, transport, or availability behavior is affected
- `docs/MVP_APP_STRUCTURE.md`:
  - only when the change affects screens, navigation, flows, or UX responsibilities
- `docs/PROJECT_SETUP.md`:
  - only when build, tooling, environment, or local commands matter

Do not load `docs/DEVELOPMENT_RULES.md` as architecture context unless the task needs the implementation checklist.

## Artifact placement rule

Before creating or moving a file:

1. Run `Global Artifact Classification Workflow` from `docs/ARCHITECTURE.md`.
2. Classify artifact type and ownership boundary.
3. Place it in the canonical destination, not in a nearby convenient folder.

Default destinations:

- assets: `common/assets/`
- backend modules and infra: `backend/`
- shared config: `shared/config/`
- transport contracts: `shared/contracts/`
- shared domain: `shared/domain/`
- shared application orchestration: `shared/application/`
- shared persistence contracts: `shared/persistence/`
- Apple-only shared code: `apple/shared/`
- platform-specific app code: the relevant platform directory
- automation: `tooling/scripts/`
- CI helpers: `tooling/ci/`
- templates: `tooling/templates/`
- docs: `docs/`

Apple contract mirror rule:

- `shared/contracts/` is the canonical contract spec.
- Apple Xcode targets cannot consume it directly.
- Matching app-local build-input copies in `App/Models/Contracts/` must stay structurally in sync in the same change.

## Architecture and UI rules

- Prefer minimal, additive changes.
- Keep shared logic out of platform UI layers.
- Keep platform-specific UI and integrations out of `shared/`.
- Prefer native platform components for user-facing work.
- Pages compose UI from typed projections or feature state.
- Components render typed input and emit typed user intents.
- UI code must not call transport clients directly.
- Feature flows own event handling, state transitions, and effects.
- Initial load and later updates must enter the same explicit event pipeline for the active mode.

## Documentation maintenance

- Update the relevant canonical doc in the same change when behavior or structure changes.
- `docs/ARCHITECTURE.md`: layers, module boundaries, placement rules, component taxonomy, event-flow rules
- `docs/TYPES_AND_CONTRACTS.md`: entities, relations, identifiers, model boundaries
- `docs/SYNC_RULES.md`: board-mode authority, write-path, availability, transition rules
- `docs/MVP_APP_STRUCTURE.md`: sections, shells, entry points, navigation, UX flow responsibilities
- `docs/DECISIONS.md`: notable architectural decisions
- `docs/OPEN_QUESTIONS.md`: unresolved structural or product gaps

Treat undocumented structural, UX, or sync changes as incomplete work.

## Validation rule

- After implementation work, run the most relevant build, test, lint, or diagnostics step available for the touched project.
- Fix errors and actionable warnings you introduce before considering the task complete.
- If full verification is not possible, run the closest available validation and report the limitation.

## Current phase

The repository is still in bootstrap.

Priority now:

- stabilize structure and conventions
- keep product-aware architecture explicit
- enforce strict offline-board vs online-board boundaries
- continue the macOS-first vertical slice
- avoid premature implementation detail
- keep placeholders lightweight and explicit
