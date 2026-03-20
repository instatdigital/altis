# Architecture

## Objective

Define a clean monorepo foundation and product-aware architecture for Altis before implementation details appear.

## Product architecture summary

Altis is a task manager built around one canonical task model with multiple presentations:

- flat list
- kanban board
- widgets powered by reusable filter definitions

Tasks should also support canonical grouping by:

- project
- board

The main product feature is filtering tasks at the widget level. This means filter definitions are part of the core architecture and must be representable in shared logic, persisted locally, and reusable by app surfaces and widgets.

Secondary architecture priority:

- offline-first storage
- `lastModifiedAt` per task
- sync by replacing the local task version with the latest backend version

This project does not currently optimize for field-level merge resolution. The default sync strategy is full replacement of a task record using the most recent authoritative state from the backend.

Additional active capabilities:

- collaboration
- real-time updates while connected
- native Apple ID authorization

Deferred capabilities:

- calendar sync
- Google authorization

## Canonical domain concepts

### Task

Core shared entity used by all platforms and all presentation modes.

### Project

Canonical grouping entity for tasks. Projects are a first-class part of product navigation and should not be modeled as an optional label-like extension.

### Board

Canonical grouping entity for board-based task organization. Boards belong to a project context and provide kanban-oriented structure over tasks.

### TaskFilter

First-class domain concept. Must not be modeled as screen-only state because it drives widget behavior and should be portable across app surfaces.

### TaskCollectionView

Presentation-specific projection over the same task set. Flat list and kanban are views over one shared domain, not separate storage models. Project and board context shape the projection but do not create separate task entities.

### SyncMetadata

Shared sync metadata including `lastModifiedAt`, sync status, and backend authority assumptions.

## MVP application sections

The first application architecture should revolve around these canonical sections:

### Auth

Authentication for online capabilities. Required for sync, collaboration, and server-backed profile data. Offline task access should still be possible when local data exists.

### Task List

Default high-density task browsing mode. This is the baseline presentation and should remain the simplest path to task capture and review.

### Kanban Board

Alternative presentation over the same canonical task model. Board movement should map to task state transitions, not a separate storage shape.

### Task Page

Single-task detail and editing surface. This is the canonical place for task metadata beyond compact list and board cards.

### Project

A project-level scope for tasks, boards, and future collaboration boundaries.

### Board

A board-level scope for kanban organization inside a project.

### Profile

User identity, account-level data, and future collaboration context.

### Settings

Application settings including theme, future sync preferences, and other device-level options.

### Theme Switching

A cross-cutting concern that should be supported by common assets and shared presentation rules, not as an isolated screen-only implementation.

## MVP navigation contract

At MVP level, the app should support:

- a primary task browsing entry point
- project-aware task browsing
- board-aware kanban browsing
- a switch between list and kanban modes
- direct navigation into a task page
- profile and settings access outside the main task browsing flow
- online authorization entry points when network-backed features are used

Todoist is a useful reference for clarity, task density, and low-friction navigation, but Altis should keep widget filtering, offline behavior, and Apple-native patterns as its own priorities.

## Interface architecture principles

- Prefer native platform components and interaction patterns for user-facing UI.
- Use custom shared UI only when native components do not satisfy a real product requirement.
- Keep platform shells aligned with their platform navigation, input, typography, accessibility, and motion expectations.
- Treat platform guideline compliance as a verification step, not as an optional polish phase.

For Apple platforms specifically:

- prefer SwiftUI and native Apple controls first
- preserve expected behavior for sheets, navigation, lists, menus, drag and drop, and settings surfaces
- check UI changes against current Apple Human Interface Guidelines before considering the task complete

## Layer model

### `common/assets`

Shared assets and visual metaphors used across platforms. Theme switching must be supported through explicit light and dark variants where needed.

### `shared`

Cross-platform business logic, domain rules, task and filter models, sync contracts, persistence contracts, and portable abstractions.

### `backend`

NestJS backend services, Prisma schema and database access, auth adapters, sync endpoints, and real-time delivery infrastructure.

### `apple/shared`

Code shared by iOS and macOS but not intended for Android or Windows, including Apple-specific integrations such as widgets or Apple ID wrappers when those should stay outside fully shared code.

### `apple/ios`

iOS application shell, app-specific resources, platform integrations, and delivery configuration.

### `apple/macos`

macOS application shell, app-specific resources, platform integrations, and delivery configuration.

### Apple bootstrap layout

The current Apple bootstrap uses:

- `apple/shared/` as a Swift package for Apple-only shared code
- `apple/ios/Config/` and `apple/macos/Config/` for project-local xcconfig files
- `apple/ios/App/` and `apple/macos/App/` for future app target source files
- `apple/ios/Resources/` and `apple/macos/Resources/` for platform-only resources
- `apple/ios/Tests/`, `apple/ios/UITests/`, `apple/macos/Tests/`, and `apple/macos/UITests/` for test targets

This is a bootstrap layout, not yet a finalized Xcode workspace contract.

### `android`

Android application shell, app-specific resources, platform integrations, and delivery configuration.

### `windows`

Windows application shell, app-specific resources, platform integrations, and delivery configuration.

### `.github/workflows`

Repository CI/CD entry points. Keep workflows split by concern and platform.

### `tooling`

Automation scripts, reusable CI helpers, local developer tooling, and templates.

## Default artifact placement

Use stable paths for common artifact types so agents and humans make the same placement decisions.

- Shared assets, images, icons, and theme-dependent visual resources belong in `common/assets/`.
- Backend services, Nest modules, Prisma schema, and backend project config belong in `backend/`.
- Transport contracts and backend-facing API schemas belong in `shared/contracts/`.
- Shared domain models and rules belong in `shared/domain/`.
- Shared use-case orchestration belongs in `shared/application/`.
- Shared persistence contracts and sync-facing storage abstractions belong in `shared/persistence/`.
- Cross-platform configuration files and shared static app definitions should live in `shared/config/`.
- Cross-platform reusable components or non-platform-specific UI primitives should live in `shared/components/`.
- Cross-platform style definitions, design constants, and reusable non-asset presentation tokens should live in `shared/styles/`.
- Apple-only shared components, wrappers, and integrations should live in `apple/shared/`.
- Platform-specific resources, configs, and UI belong inside their platform directory.
- Scripts belong in `tooling/scripts/`.
- CI-specific helpers belong in `tooling/ci/`.
- Reusable templates belong in `tooling/templates/`.
- Context, process, and architecture documents belong in `docs/`.
- Apple project-local sample environment files, formatter configs, linter configs, and xcconfig files belong inside each Apple project directory.

If a needed directory does not exist yet, create the narrowest correct directory and place the new artifact there rather than choosing an unrelated existing location.

## Boundary rules

- Shared logic must not depend on platform UI frameworks.
- Backend infrastructure must not leak Prisma-specific models into client-facing contracts.
- Apple shared code may depend on Apple frameworks, but should not assume a single platform.
- Platform layers may depend on `shared` and their relevant shared layer.
- Common assets must remain platform-neutral unless a platform-specific derivative is explicitly required.
- Task, filter, persistence, and sync contracts belong in shared layers before platform adapters are added.
- Project and board are canonical domain entities and must be represented in shared contracts and shared domain rules.
- List, kanban, and widgets must consume the same canonical task model.
- Kanban organization must use board and project context, not a separate parallel task store.
- Widget filters must be serializable and stable enough for persistence and sync.
- Sync semantics default to latest-version replacement, not multi-master merge.
- Real-time transport should update the same local canonical store used by offline mode.
- Agents should validate the target path before file creation and create missing directories in the correct layer when necessary.
- New structural or workflow conventions introduced during implementation should be added to the repository rules as part of the same change.
- A completed implementation task should include the strongest available build or diagnostic verification for the affected project.
- Cross-language reuse should happen at the contract level, not by forcing one runtime type system across Swift and NestJS.
- User-facing platform UI should prefer native components and should be checked against relevant platform guidelines after UI changes.

## Growth path

If module count grows, introduce package managers or submodules inside these existing layers rather than flattening the repository root.

## Recommended logical modules

As implementation starts, prefer these responsibilities even if they are not yet separate packages:

- `TaskDomain`: task entities, statuses, board grouping rules
- `ProjectDomain`: project entities and scoping rules
- `BoardDomain`: board entities and project relationships
- `TaskFilters`: reusable filter definitions and evaluation rules
- `TaskPersistence`: local storage contracts and offline snapshots
- `TaskSync`: backend sync and version replacement logic
- `TaskCollaboration`: presence, shared updates, live delivery contracts
- `TaskAuth`: user session and provider abstractions
- `TaskContracts`: API request and response contracts shared conceptually across clients and backend

## Backend architecture direction

The backend stack is:

- NestJS for application structure and modules
- Prisma for database access and schema management

Recommended backend modules for MVP:

- `auth`
- `profile`
- `tasks`
- `task-filters`
- `projects`
- `boards`
- `settings`
- `realtime`
- `health`

Prisma should remain an implementation detail of the backend. Shared contracts should describe transport payloads and domain concepts, not raw Prisma-generated types. The preferred direction is OpenAPI-first contracts for backend-client boundaries.

## Non-goals for the current phase

- calendar integration
- Google authorization
- advanced conflict-free replicated data types
- separate architectures per platform for the same task behavior
