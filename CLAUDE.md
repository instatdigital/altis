# Altis Claude Context

This file is a Claude-specific entry point, not the primary source of repository rules.

## Source of truth

- Global monorepo rules live in `AGENTS.md`.
- Architecture, placement, workflow, and validation rules live in `docs/`.
- Platform-specific or layer-specific rules should live close to the platform or layer they govern.
- When duplicate working copies exist, the real Xcode project path is the source of truth for file edits, not an autosave mirror.

Claude should treat `AGENTS.md` as the default source of truth for repository-wide expectations and should avoid duplicating those rules here.

## How to read context

For non-trivial work, read in this order:

1. `AGENTS.md`
2. `README.md`
3. `docs/ARCHITECTURE.md`
4. `docs/TYPES_AND_CONTRACTS.md` when the task touches entities, relations, persistence models, or UI projections
5. `docs/DEVELOPMENT_RULES.md`
6. `docs/SYNC_RULES.md` when the task touches data flow, state, persistence, or networking
7. `docs/PROJECT_SETUP.md`
8. `docs/DECISIONS.md`
9. the nearest platform or layer README for the touched area

## Scope rules

- Do not copy monorepo-wide rules from `AGENTS.md` into platform files unless the platform intentionally overrides or narrows them.
- Keep global rules global.
- Keep platform-specific rules in platform directories.
- Keep backend-specific rules in backend directories.
- When a new rule applies to the whole repository, update `AGENTS.md` or the relevant file in `docs/`, not this file.
- When a new rule applies only to one platform or one layer, update the nearest platform or layer README instead of adding a second monorepo-wide copy.
- If both a real project path and an autosave copy exist, verify the active project root before editing and commit changes into the real project path.

## Platform references

Use these files for local context after reading the global rules:

- Apple layer: `apple/README.md`
- iOS: `apple/ios/README.md`
- macOS: `apple/macos/README.md`
- Android: `android/README.md`
- Windows: `windows/README.md`
- backend: `backend/README.md`

## Purpose of this file

This file should stay short. It exists to point Claude to the canonical monorepo instructions and the nearest local rules without becoming another competing rule document.
