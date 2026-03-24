# Altis iOS

Bootstrap for the iOS application project.

## Agent Context (Canonical Docs)

Before implementation work in `apple/ios`, load:

- `../../AGENTS.md`
- `../README.md`
- `../../docs/ARCHITECTURE.md`:
  - `Layer model`
  - `Default artifact placement`
  - `Global Artifact Classification Workflow`
  - relevant Apple and feature sections
- `../../docs/TYPES_AND_CONTRACTS.md` only for touched entities
- `../../docs/SYNC_RULES.md` when board, task, persistence, transport, or availability behavior is affected
- `../../docs/MVP_APP_STRUCTURE.md` when screens, navigation, or UX flow responsibilities are affected
- `../../docs/PROJECT_SETUP.md` when setup, build commands, or tooling matter

## Planned ownership

- iOS app shell
- iOS-specific resources
- iOS-specific integrations
- iOS tests and UI tests

## Expected future project shape

- `App/`
- `Resources/`
- `Tests/`
- `UITests/`
- `Config/`

## Bootstrap Xcode project

Generate the `.xcodeproj` from repository root:

```bash
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb --platform=ios
```

Generated project path:

- `apple/ios/AltisIOS.xcodeproj`
