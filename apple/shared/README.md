# Altis Apple Shared

Apple-only shared code for iOS and macOS lives here.

## Intended responsibilities

- Apple framework adapters reused by both apps
- widget support shared across Apple platforms when appropriate
- Apple ID integration wrappers
- platform-neutral SwiftUI or Foundation code that is still Apple-only

## Not for this layer

- cross-platform domain contracts that belong in `shared/`
- iOS-only app shell code
- macOS-only app shell code
