# Apple Layer

This layer contains Apple-platform work split into:

- `shared/` for Apple-only shared code
- `ios/` for the iOS application project
- `macos/` for the macOS application project

## Current bootstrap state

- `apple/shared` is initialized as a Swift package for Apple-only shared code
- `apple/ios` contains project-local setup, config, and target placeholders
- `apple/macos` contains project-local setup, config, and target placeholders

## Rules

- Keep cross-platform domain and sync contracts out of this layer unless they are Apple-only integrations.
- Put widgets, Apple ID wrappers, and Apple framework adapters in `apple/shared` when they are reused by both Apple apps.
- Keep project-local environment files, formatter configs, linter configs, and setup docs close to each Apple project.
