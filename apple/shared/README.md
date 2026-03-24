# Altis Apple Shared

Apple-only shared code for iOS and macOS lives here.

## Agent Context (Canonical Docs)

Before implementation work in `apple/shared`, load:

- `../../AGENTS.md`
- `../README.md`
- `../../docs/ARCHITECTURE.md`:
  - `Layer model`
  - `Default artifact placement`
  - `Global Artifact Classification Workflow`
  - relevant Apple shared sections
- `../../docs/TYPES_AND_CONTRACTS.md` only for touched entities
- `../../docs/SYNC_RULES.md` when board, task, persistence, transport, or availability behavior is affected
- `../../docs/MVP_APP_STRUCTURE.md` when shared UI or flow responsibilities are affected
- `../../docs/PROJECT_SETUP.md` when setup, commands, or tooling matter

## Intended responsibilities

- Apple framework adapters reused by both apps
- Apple-only shared UI or wrappers
- widget support shared across Apple platforms when appropriate
- Apple ID integration wrappers

## Not for this layer

- cross-platform domain contracts that belong in `shared/`
- iOS-only app shell code
- macOS-only app shell code
