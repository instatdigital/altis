# Altis macOS

Bootstrap for the macOS application project.

## Agent Context (Canonical Docs)

Before implementation work in `apple/macos`, load:

- `../../AGENTS.md`
- `../README.md`
- this README
- only the canon required by the task, following `AGENTS.md#Lean context bootstrap`
- `MACOS_MVP_TASK_BREAKDOWN.md` only when the task is tied to the current macOS phase plan or requires checkbox updates

Default extra focus:

- placement and ownership:
  - `../../docs/ARCHITECTURE.md` with `Global Artifact Classification Workflow`
- setup or build commands:
  - `../../docs/PROJECT_SETUP.md`

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
