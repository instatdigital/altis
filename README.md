# Altis

Monorepo for the Altis product family.

Current goal: establish a stable repository structure before platform-specific implementation starts.

## Top-level layout

- `common/` shared assets, visual metaphors, and theme-dependent resources
- `shared/` cross-platform domain and application logic
- `apple/shared/` Apple-only shared code for iOS and macOS
- `apple/ios/` iOS application targets and resources
- `apple/macos/` macOS application targets and resources
- `android/` Android application targets and resources
- `windows/` Windows application targets and resources
- `tooling/` scripts, CI helpers, templates, and automation
- `.github/workflows/` GitHub Actions workflows
- `docs/` architecture and delivery documentation

## Agent context

- `AGENTS.md` is the global routing layer for repository work.
- `CLAUDE.md` is a thin Claude entry point and should stay shorter than `AGENTS.md`.
- Canonical product and architecture rules live in `docs/`.
- Placement decisions always go through `docs/ARCHITECTURE.md#Global Artifact Classification Workflow`.
