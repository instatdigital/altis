# Altis Apple Shared

Apple-only shared code for iOS and macOS lives here.

## Agent Context (Canonical Docs)

Before implementation work in `apple/shared`, load:

- `../../AGENTS.md`
- `../README.md`
- this README
- only the canon required by the task, following `AGENTS.md#Lean context bootstrap`

Default extra focus:

- placement and ownership:
  - `../../docs/ARCHITECTURE.md` with `Global Artifact Classification Workflow`
- shared Apple wrappers or adapters:
  - relevant Apple sections in `../../docs/ARCHITECTURE.md`

## Intended responsibilities

- Apple framework adapters reused by both apps
- Apple-only shared UI or wrappers
- widget support shared across Apple platforms when appropriate
- Apple ID integration wrappers

## Not for this layer

- cross-platform domain contracts that belong in `shared/`
- iOS-only app shell code
- macOS-only app shell code
