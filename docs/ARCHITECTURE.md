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

### BoardStage

Canonical workflow entity inside board context. Board stages are ordered, reusable in projections, and define how tasks progress through a board workflow.

### BoardStagePreset

Reusable definition of board stages that may be used when creating new boards. Presets are not board-local visual shortcuts; they are reusable workflow templates.

Board stage presets are workspace-level definitions. Board creation copies a preset into board-local stages rather than maintaining a live link.

### TaskFilter

First-class domain concept. Must not be modeled as screen-only state because it drives widget behavior and should be portable across app surfaces.

### TaskCollectionView

Presentation-specific projection over the same task set. Flat list and kanban are views over one shared domain, not separate storage models. Project, board, and board-stage context shape the projection but do not create separate task entities.

### SyncMetadata

Shared sync metadata including `lastModifiedAt`, sync status, and backend authority assumptions.

## UI composition model

Application UI should be understood as three cooperating architectural roles:

- visual components
- typed data models and projections
- pages or containers that assemble visual components and bind them to feature flows

This may resemble MVVM structurally, but the project decision is event-driven rather than passive view-model mutation.

Rules:

- Visual components MUST be able to render from typed incoming data and typed UI state.
- Visual components SHOULD remain reusable and MUST NOT own persistence or transport logic.
- Pages or feature containers MUST assemble visual components, subscribe to the required event and state flows, and dispatch feature events.
- Data handling MUST remain consistent and typed across local persistence, application logic, and transport mapping.
- Reusable pages, layouts, and isolated components MUST integrate with local or global event flows through explicit subscriptions and event dispatch, not through hidden mutable singletons.

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

### Board Stage Management

Board workflow definition through ordered stages, terminal outcomes, and reusable stage presets.

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

## UX architecture source

`docs/MVP_APP_STRUCTURE.md` is the canonical source for product-level UX architecture:

- section boundaries
- shell responsibilities
- canonical user flows
- context switching rules
- widget-to-app handoff expectations

This file should define structural architecture and layer boundaries. It should reference UX architecture, not replace it with duplicated flow prose.

## Interface architecture principles

- Prefer native platform components and interaction patterns for user-facing UI.
- Use custom shared UI only when native components do not satisfy a real product requirement.
- Keep platform shells aligned with their platform navigation, input, typography, accessibility, and motion expectations.
- Treat platform guideline compliance as a verification step, not as an optional polish phase.
- UI implementation may use native widgets and controls, but UX architecture, state flow, and data contracts must remain explicit in project documentation.

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

Apple local persistence direction:

- Apple clients use SQLite-backed local persistence for offline-first storage, local projections, outbox behavior, and sync metadata.

## App feature structure

When platform app implementation starts, each app should use a predictable feature-first layout inside its app directory.

Recommended app-local directories:

- `App/Shell/` for app entry, root navigation, and global shell composition
- `App/Features/<FeatureName>/Page/` for route-level screens or page containers
- `App/Features/<FeatureName>/Components/` for feature-local reusable UI pieces
- `App/Features/<FeatureName>/State/` for feature state, events, reducers, and effect coordination
- `App/Features/<FeatureName>/Models/` for view-facing models that are local to the feature
- `App/Features/<FeatureName>/Utilities/` for feature-local helpers that should not be shared wider
- `App/SharedUI/` for app-local reusable UI that is shared by multiple features within one app
- `App/Navigation/` for navigation contracts, route definitions, and app-level coordinators
- `App/Platform/` for app-only platform integrations that do not belong in `apple/shared/`

Placement rules:

- A page belongs to exactly one feature boundary.
- A feature-local component should not move to `App/SharedUI/` until it is reused by multiple features with the same semantics.
- An app-local utility should not move to `apple/shared/` or `shared/` until it is needed by another ownership boundary.
- Shared cross-platform UI primitives belong in `shared/components/` only if they are not platform-framework-specific.
- Apple-only reusable UI and wrappers belong in `apple/shared/` when they are shared by both iOS and macOS.

## Event-driven interface model

UI state should be event-driven across app features. The intended model is similar in spirit to BLoC, but defined in repository-neutral terms so it can be implemented with platform-native tools.

Core flow:

- views emit feature events
- a feature state owner handles events
- the feature state owner updates render state
- the feature state owner triggers effects through application and persistence boundaries
- effect results re-enter the feature as events

Feature event sources may include:

- explicit user actions
- lifecycle events such as load, refresh, foreground, and restore
- sync completion and retry events
- real-time backend events
- navigation result events

Feature state rules:

- A view renders from feature state and does not own business workflow decisions.
- Views must not call repositories, sync adapters, or transport clients directly.
- State mutation should happen in one feature-owned flow rather than being spread across unrelated UI callbacks.
- The same canonical task store must feed list, kanban, widgets, and task detail projections.
- Real-time and sync updates must enter the same event flow as local user edits when they affect the same feature state.
- Navigation that changes feature state should be representable as events and state transitions rather than hidden imperative side effects.

This model is intentionally broader than a specific framework so each platform can map it to native implementation patterns without losing the architectural rule.

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
- Route-level pages and feature containers should live under `App/Features/<FeatureName>/Page/` inside the target app.
- Feature-local reusable UI should live under `App/Features/<FeatureName>/Components/` inside the target app.
- App-local shared UI should live under `App/SharedUI/` inside the target app.
- Feature-owned event, state, reducer, and effect coordination should live under `App/Features/<FeatureName>/State/` inside the target app.
- Feature-local utilities should live under `App/Features/<FeatureName>/Utilities/` unless a wider ownership boundary is justified.
- App-wide navigation contracts and shell coordination should live under `App/Navigation/` and `App/Shell/`.
- Scripts belong in `tooling/scripts/`.
- CI-specific helpers belong in `tooling/ci/`.
- Reusable templates belong in `tooling/templates/`.
- Context, process, and architecture documents belong in `docs/`.
- Apple project-local sample environment files, formatter configs, linter configs, and xcconfig files belong inside each Apple project directory.

If a needed directory does not exist yet, create the narrowest correct directory and place the new artifact there rather than choosing an unrelated existing location.

## Event-driven app flow

The project uses an event-driven application architecture analogous to BLoC.

Minimum architectural roles:

- `Page` or `Container`: assembles the screen, connects flows, and dispatches feature events
- `VisualComponent`: renders typed input and emits user intents
- `FeatureFlow`: owns event handling, state transitions, effect coordination, and subscriptions
- `DataWorker`: isolated data-facing class or service that talks to persistence, outbox, sync, and transport boundaries

Flow rules:

- Pages MUST subscribe to the flows required for their responsibility.
- Reusable components MAY subscribe to narrow local flows when that is part of their documented responsibility, but MUST NOT bypass the feature flow for domain behavior.
- Feature flows MUST consume user events, lifecycle events, realtime events, and sync events through one coherent event pipeline.
- Initial data load and later online updates must enter the same feature flows through one coherent ingestion path rather than separate UI-only and online-only pipelines.
- Feature flows MUST work with typed state and typed events.
- Data workers MUST encapsulate data access and sync coordination behind typed interfaces.
- UI-facing components MUST NOT call transport clients or repository internals directly.
- Data returned from the network MUST update local state first; UI MUST observe local projections.

For offline-first synchronization rules, see `docs/SYNC_RULES.md`.

## Component taxonomy

All UI and UI-adjacent components should be classified before reuse, extension, or creation.

Canonical component types:

- `Layout`: arranges child content and spacing without being the primary interaction surface
- `Container`: owns composition, state binding, feature wiring, or contextual presentation for a bounded section
- `Interactive`: generic user-action surface that is not semantically narrower than a button, toggle, field, or link
- `Button`: explicit action trigger
- `Link`: navigation or external destination trigger
- `Field`: text, numeric, date, search, or other direct user input surface
- `Selection`: picker, toggle group, segmented control, checkbox, radio, or choice surface
- `Display`: read-only presentational element such as label, badge, avatar, icon row, metadata line, or status chip
- `Feedback`: empty state, error state, loading state, toast, banner, alert, or validation messaging surface
- `Overlay`: modal, sheet, popover, tooltip, dialog, menu, or contextual surface layered over another flow
- `ListItem`: reusable row, cell, card, or task tile used inside a collection
- `Navigation`: tabs, sidebar sections, breadcrumbs, route switchers, or other navigation-specific elements
- `Bridge`: wrapper around native platform UI, system controls, or framework-specific adapters

Ownership classification must also be explicit:

- feature-local
- app-local
- platform-shared
- cross-platform shared

Placement level must also be explicit:

- `platform app`: code that is valid only inside one concrete app such as `apple/macos` or `apple/ios`
- `Apple shared`: code reusable by both Apple apps but not suitable for non-Apple platforms
- `global shared`: code reusable across product platforms and not coupled to Apple-only APIs or UI frameworks

## Component ownership escalation

Components must not be promoted to a wider level only because they look reusable.

Escalation order:

1. start at the narrowest valid level
2. promote to a wider level only when there is a real second consumer at that level
3. document the wider ownership when promotion changes architectural expectations

Level rules:

- A component MUST stay in `platform app` if it depends on app-local navigation, app-local feature flow, platform-only UI assumptions, or platform-specific APIs not intended for the sibling app.
- A component MAY move to `Apple shared` only if it is already needed by both iOS and macOS or the need is immediate and concrete, and the component remains Apple-only by nature.
- A component MUST NOT move to `global shared` if it depends on Apple frameworks, Apple interaction patterns, or platform-specific rendering primitives.
- A component MAY move to `global shared` only if its semantics, data contract, and dependencies are platform-neutral.
- If the wider level would force leaky abstractions, conditional behavior, or platform-specific branches into the component API, the component MUST remain at the narrower level.
- Shared placement is earned by validated reuse, not by speculative architecture.

## Component reuse algorithm

When a task needs a component, use this order:

1. classify the component by type and ownership boundary
2. search for an existing component with matching semantics
3. reuse the existing component if it already fits
4. extend the closest existing component if it can absorb the need without breaking its meaning or ownership
5. create a new component only when reuse or extension would create semantic confusion, ownership leakage, or excessive branching

Extension checks should include:

- whether the existing component keeps a coherent responsibility after the change
- whether the wider API would still match the component name and ownership
- whether the change promotes the component into a wider reuse boundary
- whether the component is being promoted to the correct placement level: `platform app`, `Apple shared`, or `global shared`

If extension widens ownership or changes the intended reuse scope, document that change in the relevant architecture or platform README.

## Boundary rules

- Shared logic must not depend on platform UI frameworks.
- Backend infrastructure must not leak Prisma-specific models into client-facing contracts.
- Apple shared code may depend on Apple frameworks, but should not assume a single platform.
- Platform layers may depend on `shared` and their relevant shared layer.
- Common assets must remain platform-neutral unless a platform-specific derivative is explicitly required.
- Task, filter, persistence, and sync contracts belong in shared layers before platform adapters are added.
- Project and board are canonical domain entities and must be represented in shared contracts and shared domain rules.
- Board stages and board stage presets are canonical workflow entities and must be represented in shared contracts and shared domain rules.
- List, kanban, and widgets must consume the same canonical task model.
- Kanban organization must use board and project context, not a separate parallel task store.
- List, task detail, and kanban must agree on the task's current board stage when a board workflow is active.
- Every staged board must define one terminal successful stage and one terminal unsuccessful stage.
- Terminal successful and unsuccessful actions must move tasks into explicit terminal stages rather than setting a disconnected completion flag outside board workflow.
- Widget filters must be serializable and stable enough for persistence and sync.
- Sync semantics default to latest-version replacement, not multi-master merge.
- Real-time transport should update the same local canonical store used by offline mode.
- Agents should validate the target path before file creation and create missing directories in the correct layer when necessary.
- New structural or workflow conventions introduced during implementation should be added to the repository rules as part of the same change.
- A completed implementation task should include the strongest available build or diagnostic verification for the affected project.
- Cross-language reuse should happen at the contract level, not by forcing one runtime type system across Swift and NestJS.
- User-facing platform UI should prefer native components and should be checked against relevant platform guidelines after UI changes.
- Every implementation task should declare a target feature and expected layer boundaries before code changes begin.
- If implementation crosses the original task boundary, the new placement or workflow rule must be documented in the same change.
- App features should update UI through explicit event-driven state transitions rather than direct service calls from views.

## Growth path

If module count grows, introduce package managers or submodules inside these existing layers rather than flattening the repository root.

## Recommended logical modules

As implementation starts, prefer these responsibilities even if they are not yet separate packages:

- `TaskDomain`: task entities, statuses, board grouping rules
- `ProjectDomain`: project entities and scoping rules
- `BoardDomain`: board entities and project relationships
- `BoardWorkflow`: board stages, terminal stage rules, and stage preset definitions
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
