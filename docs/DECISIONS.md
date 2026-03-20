# Decisions

## ADR-0001: Bootstrap repository by platform and shared layers

Status: accepted

Decision:
Use a top-level layered monorepo structure:

- `common/assets`
- `shared`
- `apple/shared`
- `apple/ios`
- `apple/macos`
- `android`
- `windows`
- `.github/workflows`
- `tooling`
- `docs`

Rationale:
This keeps platform boundaries obvious while preserving a single place for shared logic and assets.
