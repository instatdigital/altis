# Altis iOS

Bootstrap for the iOS application project.

## Planned ownership

- iOS app shell
- iOS-specific resources
- iOS-specific integrations
- iOS tests and UI tests

## Local setup contract

- project-level sample environment file: `.env.example`
- formatter configuration: `.swift-format`
- linter configuration: `.swiftlint.yml`
- build configuration files: `Config/*.xcconfig`

## Expected future project shape

- `App/` app entry points and target code
- `Resources/` app assets and other iOS-only resources
- `Tests/` unit and integration tests
- `UITests/` UI automation tests
- `Config/` xcconfig files and build settings
