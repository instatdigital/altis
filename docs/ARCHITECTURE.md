# Architecture

## Objective

Define a stable monorepo and product architecture for Altis before implementation diverges.

## Product architecture summary

Altis is a task manager built around one canonical task model with multiple presentations:

- flat list
- kanban board
- widgets powered by reusable filter definitions

Tasks and boards still support canonical grouping by:

- project
- board

The main product feature remains widget-level filtering.

The key architecture rule is now explicit board mode:

- `offline` boards are stored and edited only locally
- `online` boards are loaded and edited only through backend APIs

There is no offline-online synchronization layer between those modes. The product must not pretend that one board can seamlessly switch authority between local storage and backend state.

Only `Board` is explicitly typed by mode. Related board-owned entities inherit storage and authority from the board they belong to. Workspace-scoped support entities such as filters and stage presets remain shared client-side entities in the current phase.

Additional active capabilities:

- collaboration for online boards
- real-time updates while connected for online boards
- native Apple ID authorization for online capabilities

Deferred capabilities:

- calendar sync
- Google authorization

## Canonical domain concepts

### Task

Core shared entity used by all platforms and all presentation modes.

### Project

Canonical grouping entity for tasks and boards.

### Board

Canonical workflow entity for kanban organization inside a project.

Every board MUST declare a board mode:

- `offline`
- `online`

Board mode is a business rule, not a view preference.

### BoardStage

Ordered workflow stage inside board context.

### BoardStagePreset

Reusable definition of board stages that may be used when creating new boards.

### TaskFilter

First-class domain concept used by app surfaces and widgets.

### TaskCollectionView

Presentation-specific projection over the same task set. Flat list and kanban remain views over one shared task domain.

### BoardMode

Canonical value describing data authority:

- `offline`: the board and its board-owned data are local-only
- `online`: the board and its board-owned data are backend-backed

## UI composition model

Application UI should be understood as three cooperating roles:

- visual components
- typed data models and projections
- pages or containers that assemble visual components and bind them to feature flows

Rules:

- Visual components MUST render from typed incoming data and typed UI state.
- Visual components MUST NOT own persistence or transport logic.
- Pages or feature containers MUST assemble visual components, subscribe to required flows, and dispatch feature events.
- Data handling MUST remain explicit and typed across local persistence, application logic, and transport mapping.

## MVP application sections

The first application architecture revolves around these canonical sections:

### Auth

Authentication for online boards and other server-backed capabilities.

### Home

Landing surface for the normal app shell and board navigation.

### Task List

Default high-density task browsing mode.

### Kanban Board

Alternative presentation over the same canonical task model.

### Task Page

Single-task detail and editing surface.

### Project

Project-level scope for tasks and boards. A project may contain both offline and online boards and remains client-owned in the current phase.

### Board

Board-level scope for kanban organization inside a project.

### Board Stage Management

Board workflow definition through ordered stages, terminal outcomes, and reusable stage presets.

### Profile

User identity and account-level context for online capabilities.

### Settings

Application settings including theme and device-level preferences.

## MVP navigation contract

At MVP level, the app should support:

- a primary task browsing entry point
- project-aware task browsing
- board-aware kanban browsing
- a switch between list and kanban modes
- direct navigation into a task page
- profile and settings access outside the main task browsing flow
- online authorization entry points when online boards are used
- board-mode choice during board creation

## UX architecture source

`docs/MVP_APP_STRUCTURE.md` is the canonical source for product-level UX architecture.

## Interface architecture principles

- Prefer native platform components and interaction patterns for user-facing UI.
- Use custom shared UI only when native components do not satisfy a real product requirement.
- Keep platform shells aligned with platform navigation, input, typography, accessibility, and motion expectations.

For Apple platforms specifically:

- prefer SwiftUI and native Apple controls first
- preserve expected behavior for sheets, navigation, lists, menus, drag and drop, and settings surfaces

## Layer model

### `common/assets`

Shared assets and visual metaphors used across platforms.

### `shared`

Cross-platform domain rules, application logic, transport contracts, and local persistence contracts.

### `backend`

NestJS backend services, Prisma schema and database access, auth adapters, and online-board APIs.

### `apple/shared`

Code shared by iOS and macOS but not intended for Android or Windows.

### `apple/ios`

iOS application shell, resources, platform integrations, and delivery configuration.

### `apple/macos`

macOS application shell, resources, platform integrations, and delivery configuration.

### Apple bootstrap layout

The current Apple bootstrap uses:

- `apple/shared/` as a Swift package for Apple-only shared code
- `apple/ios/Config/` and `apple/macos/Config/` for xcconfig files
- `apple/ios/App/` and `apple/macos/App/` for app target source files
- `apple/ios/Resources/` and `apple/macos/Resources/` for platform-only resources
- `apple/ios/Tests/`, `apple/ios/UITests/`, `apple/macos/Tests/`, and `apple/macos/UITests/` for test targets

Apple local persistence direction:

- Apple clients use SQLite-backed local persistence for offline boards only.
- Online boards may use in-memory feature state or short-lived caches, but they do not own durable offline task state.
- Projects and workspaces may contain both offline and online boards.
- Projects remain client-owned and locally persisted in the current phase.
- Workspace-scoped filters and stage presets remain locally persisted support entities in the current phase.

Apple transport contract placement:

- `shared/contracts/` is the canonical documentation source and cross-platform reference for transport contract definitions.
- `shared/contracts/` is a plain monorepo directory, not a Swift Package. Apple Xcode targets cannot consume it directly.
- Each Apple platform app MUST declare its own copy of the transport contract inside its app target (e.g. `App/Models/Contracts/`) and keep it structurally in sync with `shared/contracts/`.
- The app-local copy is the active Xcode build input; `shared/contracts/` is the canonical specification.
- When either copy is updated, the other MUST be updated in the same change to prevent divergence.

## App feature structure

Recommended app-local directories:

- `App/Shell/` for app entry, root navigation, and global shell composition
- `App/Features/<FeatureName>/Page/` for route-level screens or page containers
- `App/Features/<FeatureName>/Components/` for feature-local reusable UI pieces
- `App/Features/<FeatureName>/State/` for feature state, events, reducers, and effect coordination
- `App/Features/<FeatureName>/Models/` for view-facing models that are local to the feature
- `App/Features/<FeatureName>/Utilities/` for feature-local helpers
- `App/SharedUI/` for app-local reusable UI shared by multiple features within one app
- `App/Navigation/` for navigation contracts, route definitions, and app-level coordinators
- `App/Platform/` for app-only platform integrations that do not belong in `apple/shared/`

## Event-driven interface model

UI state should be event-driven across app features.

Core flow:

- views emit feature events
- a feature state owner handles events
- the feature state owner updates render state
- the feature state owner triggers effects through local persistence or transport boundaries
- effect results re-enter the feature as events

Feature event sources may include:

- explicit user actions
- lifecycle events such as load, refresh, foreground, and restore
- network success or failure events for online boards
- navigation result events

Feature state rules:

- A view renders from feature state and does not own business workflow decisions.
- Views must not call repositories or transport clients directly.
- The same canonical task meaning must feed list, kanban, widgets, and task detail projections.
- Offline board updates and online board responses MUST enter the same feature flow for the active board mode.
- Non-board tasks and workspace-scoped support entities MUST use the feature flow that owns them rather than inferring authority from a board that may not exist.

## Default artifact placement

Use stable paths for common artifact types:

- shared assets, images, icons, and theme-dependent resources -> `common/assets/`
- backend services, Nest modules, Prisma schema, and backend project config -> `backend/`
- transport contracts and backend-facing API schemas -> `shared/contracts/` (canonical spec; see "Apple transport contract placement" below for Xcode build-input mirror rule)
- shared domain models and rules -> `shared/domain/`
- shared use-case orchestration -> `shared/application/`
- shared local persistence contracts and store abstractions -> `shared/persistence/`
- cross-platform configuration files and shared static app definitions -> `shared/config/`
- cross-platform reusable components or non-platform-specific UI primitives -> `shared/components/`
- Apple-only shared components, wrappers, and integrations -> `apple/shared/`
- platform-specific resources, configs, and UI -> platform directory
- route-level pages and feature containers -> `App/Features/<FeatureName>/Page/`
- feature-local reusable UI -> `App/Features/<FeatureName>/Components/`
- feature-owned event, state, reducer, and effect coordination -> `App/Features/<FeatureName>/State/`
- app-wide navigation contracts and shell coordination -> `App/Navigation/` and `App/Shell/`
- scripts -> `tooling/scripts/`
- CI helpers -> `tooling/ci/`
- templates -> `tooling/templates/`
- architecture, product, and process docs -> `docs/`

## Global Artifact Classification Workflow

This workflow is mandatory before creating, moving, or reviewing files in any platform scope.

Use this order:

1. Classify artifact type.
2. Classify ownership boundary.
3. Map to the canonical destination path.
4. Verify that the nearest platform or layer README links back to this workflow and canonical docs.

Artifact type classification:

- `domain entity/rule/value object` -> `shared/domain/`
- `application orchestration/use-case` -> `shared/application/`
- `transport contract/API schema` -> `shared/contracts/` as the canonical specification; for Apple Xcode targets, follow the `Apple transport contract placement` mirror rule and keep the matching app-local build-input copy in `App/Models/Contracts/` in sync in the same change
- `shared persistence contract/local store abstraction` -> `shared/persistence/`
- `apple-only shared wrapper/integration` -> `apple/shared/`
- `platform app UI/shell/feature state/platform adapter` -> platform app directory
- `backend module/infra` -> `backend/`
- `assets` -> `common/assets/`
- `automation/template/CI helper` -> `tooling/`
- `architecture/product/process docs` -> `docs/`

Ownership boundary classification:

- `platform app`
- `Apple shared`
- `global shared`

Escalation rule:

- Start at the narrowest valid ownership.
- Promote to wider ownership only with a real second consumer.
- If ownership or placement changes, update canonical docs and the affected platform or layer README in the same change.

Platform-scope context rule:

- Every platform README MUST include explicit links to:
  - `AGENTS.md`
  - `docs/ARCHITECTURE.md`
  - `docs/TYPES_AND_CONTRACTS.md`
  - `docs/SYNC_RULES.md`
  - `docs/DEVELOPMENT_RULES.md`

## Event-driven app flow

Minimum architectural roles:

- `Page` or `Container`: assembles the screen, connects flows, and dispatches feature events
- `VisualComponent`: renders typed input and emits user intents
- `FeatureFlow`: owns event handling, state transitions, effect coordination, and subscriptions
- `DataWorker`: isolated data-facing class or service that talks to local persistence or transport boundaries

Flow rules:

- Pages MUST subscribe to the flows required for their responsibility.
- Feature flows MUST consume user events, lifecycle events, and online result events through one coherent event pipeline.
- Initial data load and later updates must enter the same feature flow for the active board mode.
- Feature flows MUST work with typed state and typed events.
- Data workers MUST encapsulate data access behind typed interfaces.
- UI-facing components MUST NOT call transport clients directly.
- Offline boards MUST render from local typed projections.
- Online boards MUST render from feature-owned online state or explicit online read models, not raw transport payloads.
- A feature MUST NOT emit unavailable, blocked, or reconnect-required state unless the flow has enough evidence that the relevant online path was actually required and could not be used.
- If a canonical surface may legally contain both offline and online entities, the feature contract MUST define a real success path for each represented authority or explicitly document why one authority is out of scope for that phase.
- A placeholder gateway or routing point does not by itself satisfy a feature-flow contract; the contract is only coherent when matching state and event paths exist for both success and failure semantics that the phase claims to support.

For board-mode rules, see `docs/SYNC_RULES.md`.

## Boundary rules

- Shared logic must not depend on platform UI frameworks.
- Backend infrastructure must not leak Prisma-specific models into client-facing contracts.
- Board mode is a first-class domain concept and must be explicit in domain and transport boundaries.
- Offline boards MUST NOT depend on backend contracts, sync metadata, or reconciliation logic.
- Online boards MUST NOT pretend to be locally authoritative while disconnected.
- Offline boards use local persistence as their only durable source of truth.
- Online boards use backend APIs as their only durable source of truth.
- Offline and online boards may share task, board-stage, preset, and filter semantics, but they MUST NOT share a fake sync pipeline.
- Widgets, list, kanban, and task detail must consume the same canonical task meaning.
- Every staged board must define one terminal successful stage and one terminal unsuccessful stage.
- Widget filters must be serializable and stable enough for persistence and app handoff.
- Projects are not backend-owned by default in the current phase.
- `projectId` remains a client-owned grouping reference even when an online board is rendered through backend-backed flows.
- Workspace-scoped presets and filters are not backend-owned by default.

## Recommended logical modules

As implementation starts, prefer these responsibilities even if they are not yet separate packages:

- `TaskDomain`: task entities and statuses
- `ProjectDomain`: project entities and scoping rules
- `BoardDomain`: board entities, board mode, and project relationships
- `BoardWorkflow`: board stages, terminal stage rules, and stage preset definitions
- `TaskFilters`: reusable filter definitions and evaluation rules
- `OfflineBoardPersistence`: offline-board local storage and projections
- `OnlineBoardGateway`: online-board API integration and mapping
- `BoardModeRouting`: feature-level handling of board authority inside the same app shells
- `TaskAuth`: user session and provider abstractions
- `TaskContracts`: API request and response contracts for online boards

## Backend architecture direction

The backend stack is:

- NestJS for application structure and modules
- Prisma for database access and schema management

Recommended backend modules for MVP:

- `auth`
- `profile`
- `tasks`
- `boards`
- `settings`
- `health`

These backend modules serve only online boards and related backend-owned online entities. Projects remain client-owned grouping entities in the current phase.

Prisma should remain an implementation detail of the backend. Shared contracts should describe transport payloads and domain concepts, not raw Prisma-generated types. The preferred direction is OpenAPI-first contracts for backend-client boundaries.

## Non-goals for the current phase

- offline-online sync
- calendar integration
- Google authorization
- advanced conflict-free replicated data types
- separate architectures per platform for the same task behavior
