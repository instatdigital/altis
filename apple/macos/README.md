# Altis macOS

Bootstrap for the macOS application project.

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
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb
```

Generated project path:

- `apple/macos/AltisMacOS.xcodeproj`
