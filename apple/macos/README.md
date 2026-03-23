# Altis macOS

Bootstrap for the macOS application project.

## Agent Context (Canonical Docs)

Before any implementation work in `apple/macos`, load the repository-level canonical documents:

- `../../AGENTS.md`
- `../../docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
- `../../docs/MVP_APP_STRUCTURE.md`
- `../../docs/TYPES_AND_CONTRACTS.md`
- `../../docs/SYNC_RULES.md`
- `../../docs/DEVELOPMENT_RULES.md`
- `../../docs/PROJECT_SETUP.md`
- `../../docs/MACOS_MVP_TASK_BREAKDOWN.md`
- `../README.md`

## Planned ownership

- macOS app shell
- macOS-specific resources
- macOS-specific integrations
- macOS tests and UI tests

## Expected future project shape

- `App/`
- `Resources/`
- `Tests/`
- `UITests/`
- `Config/`

## Bootstrap Xcode project

Generate the `.xcodeproj` from repository root:

```bash
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb --platform=macos
```

Generated project path:

- `apple/macos/AltisMacOS.xcodeproj`
