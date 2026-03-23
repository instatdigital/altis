# Altis iOS

Bootstrap for the iOS application project.

## Agent Context (Canonical Docs)

Before implementation work in `apple/ios`, load:

- `../../AGENTS.md`
- `../../docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
- `../../docs/MVP_APP_STRUCTURE.md`
- `../../docs/TYPES_AND_CONTRACTS.md`
- `../../docs/SYNC_RULES.md`
- `../../docs/DEVELOPMENT_RULES.md`
- `../../docs/PROJECT_SETUP.md`
- `../README.md`

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
