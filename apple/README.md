# Apple Layer

This layer contains Apple-platform work split into:

- `shared/` for Apple-only shared code
- `ios/` for the iOS application project
- `macos/` for the macOS application project

## Rules

- Keep cross-platform domain and sync contracts out of this layer unless they are Apple-only integrations.
- Put Apple-specific wrappers or adapters shared by both apps in `apple/shared/`.

## Bootstrap projects for Xcode

From repository root run:

```bash
ruby tooling/scripts/bootstrap_apple_xcode_projects.rb
```

This generates:

- `apple/macos/AltisMacOS.xcodeproj`
- `apple/ios/AltisIOS.xcodeproj`
