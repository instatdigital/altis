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

The repository includes:

- `AGENTS.md` for Codex-style coding agents
- `CLAUDE.md` for Claude-style coding agents

These files define repository-wide expectations and should be treated as the default context for work inside `altis/`.
