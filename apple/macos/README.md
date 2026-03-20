# Altis macOS

Bootstrap for the macOS application project.

## Planned ownership

- macOS app shell
- macOS-specific resources
- macOS-specific integrations
- macOS tests and UI tests

## Local setup contract

- project-level sample environment file: `.env.example`
- formatter configuration: `.swift-format`
- linter configuration: `.swiftlint.yml`
- build configuration files: `Config/*.xcconfig`

## Expected future project shape

- `App/` app entry points and target code
- `Resources/` app assets and other macOS-only resources
- `Tests/` unit and integration tests
- `UITests/` UI automation tests
- `Config/` xcconfig files and build settings
