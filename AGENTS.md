# Altis Agent Instructions

This file defines the default context for coding agents working in the `altis` monorepo.

## Repository purpose

Altis is a multi-platform application monorepo with explicit separation between:

- shared business logic
- Apple shared code
- platform app shells
- CI/CD and tooling
- common visual assets

## Architectural boundaries

- Keep platform-independent logic in `shared/`.
- Keep Apple-specific shared code in `apple/shared/`.
- Keep iOS app code in `apple/ios/`.
- Keep macOS app code in `apple/macos/`.
- Keep Android app code in `android/`.
- Keep Windows app code in `windows/`.
- Keep reusable assets in `common/assets/`.
- Keep automation and templates in `tooling/`.

## Working rules

- Prefer minimal, additive changes.
- Do not move assets out of `common/assets/` without an explicit migration decision.
- Preserve theme-aware asset naming conventions such as `*_light` and `*_dark`.
- Document architectural decisions in `docs/DECISIONS.md`.
- Update `docs/ARCHITECTURE.md` when directory ownership or module boundaries change.
- Treat this repository as a monorepo first, platform repo second.

## Current phase

The repository is in bootstrap stage.

Expected work right now:

- define structure
- define conventions
- avoid premature implementation details
- keep placeholders lightweight and explicit
