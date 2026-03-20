# Altis Claude Context

Use this repository structure as the default mental model.

## Core layers

- `common/assets`: shared assets, styles, and theme metaphors
- `shared`: cross-platform logic and contracts
- `apple/shared`: Apple shared layer
- `apple/ios`: iOS application layer
- `apple/macos`: macOS application layer
- `android`: Android application layer
- `windows`: Windows application layer
- `.github/workflows`: GitHub Actions CI/CD
- `tooling`: scripts, CI helpers, templates
- `docs`: architecture and product documentation

## Repository expectations

- Keep changes aligned with the declared layer boundaries.
- Prefer documenting decisions before introducing cross-layer coupling.
- Keep placeholders minimal until product and platform decisions are finalized.
- Respect theme-aware resources in `common/assets/`.

## First reference files

Read these first when making non-trivial changes:

1. `README.md`
2. `docs/ARCHITECTURE.md`
3. `docs/DEVELOPMENT_RULES.md`
4. `docs/DECISIONS.md`
