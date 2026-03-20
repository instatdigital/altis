# Architecture

## Objective

Define a clean monorepo foundation for Altis before implementation details appear.

## Layer model

### `common/assets`

Shared assets and visual metaphors used across platforms. Theme switching must be supported through explicit light and dark variants where needed.

### `shared`

Cross-platform business logic, domain rules, shared contracts, and portable abstractions.

### `apple/shared`

Code shared by iOS and macOS but not intended for Android or Windows.

### `apple/ios`

iOS application shell, app-specific resources, platform integrations, and delivery configuration.

### `apple/macos`

macOS application shell, app-specific resources, platform integrations, and delivery configuration.

### `android`

Android application shell, app-specific resources, platform integrations, and delivery configuration.

### `windows`

Windows application shell, app-specific resources, platform integrations, and delivery configuration.

### `.github/workflows`

Repository CI/CD entry points. Keep workflows split by concern and platform.

### `tooling`

Automation scripts, reusable CI helpers, local developer tooling, and templates.

## Boundary rules

- Shared logic must not depend on platform UI frameworks.
- Apple shared code may depend on Apple frameworks, but should not assume a single platform.
- Platform layers may depend on `shared` and their relevant shared layer.
- Common assets must remain platform-neutral unless a platform-specific derivative is explicitly required.

## Growth path

If module count grows, introduce package managers or submodules inside these existing layers rather than flattening the repository root.
