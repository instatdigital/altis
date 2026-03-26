# Apple Layer

This layer contains Apple-platform work split into:

- `shared/` for Apple-only shared code
- `ios/` for the iOS application project
- `macos/` for the macOS application project

## Agent context bootstrap

For Apple-layer work, load:

- `../AGENTS.md`
- this README
- only the canon required by the task, using `AGENTS.md#Lean context bootstrap`

Typical Apple concerns:

- placement or ownership:
  - `../docs/ARCHITECTURE.md` with `Global Artifact Classification Workflow`
- entities or boundaries:
  - `../docs/TYPES_AND_CONTRACTS.md`
- board authority, persistence, transport, availability:
  - `../docs/SYNC_RULES.md`
- screens or UX flow:
  - `../docs/MVP_APP_STRUCTURE.md`
- setup or commands:
  - `../docs/PROJECT_SETUP.md`

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
