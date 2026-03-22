# Altis iOS

Bootstrap for the iOS application project.

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
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb
```

Generated project path:

- `apple/ios/AltisIOS.xcodeproj`
