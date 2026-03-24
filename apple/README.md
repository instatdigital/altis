# Apple Layer

This layer contains Apple-platform work split into:

- `shared/` for Apple-only shared code
- `ios/` for the iOS application project
- `macos/` for the macOS application project

## Agent context bootstrap

Before Apple-layer implementation work, load the minimum required canon:

- `../AGENTS.md`
- this README
- `../docs/ARCHITECTURE.md`:
  - `Layer model`
  - `Default artifact placement`
  - `Global Artifact Classification Workflow`
- `../docs/TYPES_AND_CONTRACTS.md` only for touched entities
- `../docs/SYNC_RULES.md` when board, task, persistence, transport, or availability behavior is affected
- `../docs/MVP_APP_STRUCTURE.md` when UX flow or screen responsibilities are affected
- `../docs/PROJECT_SETUP.md` when setup, commands, or tooling matter

## Rules

- Keep cross-platform domain and sync contracts out of this layer unless they are Apple-only integrations.
- Put Apple-specific wrappers or adapters shared by both apps in `apple/shared/`.

## Bootstrap projects for Xcode

From repository root run:

```bash
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb
```

Default behavior (`--platform` omitted) generates:

- `apple/macos/AltisMacOS.xcodeproj`

Generate iOS explicitly:

```bash
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb --platform=ios
```

Generate both:

```bash
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb --platform=all
```
