# Altis Apple Shared

Apple-only shared code for iOS and macOS lives here.

## Agent Context (Canonical Docs)

Before implementation work in `apple/shared`, load:

- `../../AGENTS.md`
- `../../docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
- `../../docs/TYPES_AND_CONTRACTS.md`
- `../../docs/SYNC_RULES.md`
- `../../docs/DEVELOPMENT_RULES.md`
- `../README.md`

## Intended responsibilities

- Apple framework adapters reused by both apps
- Apple-only shared UI or wrappers
- widget support shared across Apple platforms when appropriate
- Apple ID integration wrappers

## Not for this layer

- cross-platform domain contracts that belong in `shared/`
- iOS-only app shell code
- macOS-only app shell code
