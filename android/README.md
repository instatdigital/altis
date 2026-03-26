# Altis Android

Android application scope for Altis.

## Agent Context (Canonical Docs)

Before implementation work in `android`, load:

- `../AGENTS.md`
- this README
- only the canon required by the task, following `AGENTS.md#Lean context bootstrap`

Default extra focus:

- placement and ownership:
  - `../docs/ARCHITECTURE.md` with `Global Artifact Classification Workflow`
- setup or commands:
  - `../docs/PROJECT_SETUP.md`

## Planned ownership

- Android app shell
- Android-specific resources and integrations
- Android tests

## Placement reminder

- Keep platform-specific UI, wiring, and adapters inside `android/`.
- Keep cross-platform contracts and rules in `shared/` according to the global classification workflow.
