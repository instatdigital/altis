# MVP App Structure

## Goal

Define a canonical MVP-level application structure before detailed UI implementation starts.

This file is the source of truth for UX-level application architecture in the current phase. It describes sections, user flows, screen responsibilities, and interaction boundaries without locking the project to a visual design system.

## UX architecture principles

- UX architecture should be documented in terms of sections, flows, responsibilities, and state transitions, not visual styling.
- Native platform components may replace custom UI implementation details, but they must still fit the documented section and flow model.
- Agents must not invent new sections, navigation branches, or feature entry points unless those changes are added to this file in the same change.
- If a task changes how users enter a flow, switch context, complete an action, or return from a screen, that is a UX architecture change and must be documented here.
- Pages, layouts, and reusable visual components MUST be documented as part of an event-driven flow, not as isolated visual fragments.

## Core sections

- `Home`
- `Auth`
- `TaskList`
- `KanbanBoard`
- `TaskPage`
- `Project`
- `Board`
- `Profile`
- `Settings`

## Cross-cutting capabilities

- theme switching
- widget-level filtering
- offline-first storage
- sync with latest-version replacement
- online authorization for server-backed features

## UX responsibilities by section

### Auth

- sign in for online features
- restore session
- gate server-backed collaboration and sync controls
- return the user into the previously relevant task flow after authorization when possible

### Home

- canonical landing surface before detailed project and board work
- host placeholder dashboard content during early MVP
- provide entry points into projects, boards, and future dashboard sections
- remain placeholder-only in the first vertical slice
- not depend on live project, board, task, or dashboard data in the first vertical slice

### TaskList

- default task browsing surface
- dense scan of tasks
- quick navigation into task details
- filter application
- grouping and narrowing by project
- grouping and narrowing by board
- show the task's current board stage when a board context is active
- primary entry point for fast review and capture

### KanbanBoard

- alternate view over the same task set
- drag and drop between stage columns
- board-scoped view over tasks within a chosen project or board context
- visual workflow management over the same canonical task source
- distribution of cards by current board stage

### TaskPage

- single-task editing
- metadata editing
- future collaboration context for a specific task
- links to owning project and board context when assigned
- canonical detail surface opened from list, board, widgets, or future search results
- show compact progress through board stages when the task belongs to a staged board
- provide explicit actions to complete or close unsuccessfully when the task belongs to a staged board

### Project

- task grouping at the product level
- high-level container for related work
- default scope for task browsing, filtering, and board organization
- stable context switch for list and board projections

### Board

- grouping layer for tasks inside a project or another explicit scope
- owner of kanban-oriented organization
- source for board-specific views and future board settings
- context selector for board-based work rather than a second task system
- owner of ordered board stages
- owner of terminal successful and terminal unsuccessful stages
- owner of stage configuration actions: add to end, rename, delete
- may be created from reusable stage presets
- when a non-terminal stage is deleted, tasks from that stage move to the first available stage
- terminal stages may be renamed but must not be deleted
- every staged board preserves at least one ordinary stage plus one terminal successful and one terminal unsuccessful stage

### Profile

- account identity
- future collaboration identity
- session-related profile info

### Settings

- theme selection
- app preferences
- future sync or debug preferences

## Canonical UX shells

The MVP should be understood as a small number of stable UX shells:

- `HomeShell`: landing area for dashboards, project lists, and board entry points
- `TaskShell`: the main work area for task browsing and switching between list and kanban
- `ContextShell`: project and board selection or restoration around the same task source
- `TaskDetailFlow`: entry into a single task and return to the previous task context
- `BoardConfigurationFlow`: board stage editing and board creation from stage presets
- `AccountShell`: profile, settings, and auth-related flows outside the main task browsing surface

These shells are conceptual UX boundaries. Platform teams may implement them with native navigation containers, tabs, sidebars, split views, sheets, or stacks as appropriate.

## Page and component contract

Every user-facing surface should be decomposed into:

- `Page` or `Container`: composes the surface, subscribes to the required flows, and dispatches feature events
- `Layout`: arranges sections and child content
- `VisualComponent`: renders typed incoming data and emits user intent

Rules:

- Pages MUST bind visual components to the required local or global feature flows.
- Visual components MUST accept typed data suitable for rendering without internal transport or persistence knowledge.
- Layouts MAY be shared, but they MUST remain presentation-oriented and MUST NOT become hidden data coordinators.
- Reusable pages, layouts, and isolated components MUST integrate with documented event flows rather than inventing ad hoc data callbacks.

## Typed data contract

- UI data MUST be typed and consistent with shared domain meaning and local read models.
- Pages and components MUST render from local typed projections, not raw transport payloads.
- Components SHOULD receive only the data required for rendering and interaction.
- Feature flows MUST own translation between local data models, UI-facing state, and visual component props.

## Event-driven flow contract

The project uses an event-driven application model analogous to BLoC.

Required responsibilities:

- components emit user intents as typed events
- pages subscribe to the flows relevant to the surface they compose
- feature flows process user, lifecycle, realtime, and sync events
- feature flows work through isolated data-facing classes for persistence and synchronization
- local state changes drive rendering

UI MUST NOT depend on a separate online-only flow.

## Board stage UX contract

- staged boards use one ordered stage sequence shared by list, task detail, and kanban views
- every staged board preserves at least three stages: one ordinary stage, one terminal successful stage, and one terminal unsuccessful stage
- list mode shows the task's current stage
- task cards show a compact stage-progress line with the current stage
- kanban mode groups cards by current stage
- task cards and task pages expose an explicit complete action that moves the task to the terminal successful stage
- task cards and task pages expose an explicit close-unsuccessfully action that moves the task to the terminal unsuccessful stage
- boards may be created from reusable stage presets
- stage presets are workspace-level reusable definitions
- board creation copies a preset into board-local stage definitions
- stage preset selection belongs to board creation and board setup flows, not to task editing flows
- board stage management in MVP supports only add to end, rename, and delete
- deleting a non-terminal stage moves its tasks into the first available stage
- terminal stages may be renamed but may not be deleted

## Canonical navigation model

The MVP should support:

- entering the app through the homepage
- entering the task area as the main landing experience
- choosing or restoring a project context
- choosing a board context where relevant
- switching between list and kanban without changing the underlying task source
- opening a task page from either list or kanban
- opening a task page from a widget-driven task selection path when widgets are active
- accessing board configuration for stage setup when permitted
- accessing profile and settings from the shell level
- starting auth when online-only features are required
- returning from auth or task detail into the same task context when possible

## UX flow contracts

### Task browsing flow

- The user enters the task area.
- The app restores or selects project context.
- The app restores or selects board context when relevant.
- The user browses tasks in list or kanban mode over the same canonical task source.
- Opening a task moves the user into `TaskDetailFlow` without breaking the surrounding context.

### Task detail flow

- A task may be opened from list, kanban, widgets, and future task-oriented entry points.
- The detail surface edits the same canonical task entity.
- If the task belongs to a staged board, the detail surface shows stage progression and terminal actions.
- Leaving task detail should return the user to the originating context whenever possible.

### Context switching flow

- Project changes redefine the active task scope.
- Board changes refine the active projection inside the current or explicit project scope.
- Context changes must not create parallel task stores or separate product modes.

### Board configuration flow

- A board may be created from a reusable stage preset.
- Stage presets are workspace-level.
- Board creation copies the preset rather than linking the board to later preset changes.
- A board may manage its own stages after creation.
- Stage management supports only add to end, rename, and delete in MVP.
- A board must always preserve one terminal successful stage and one terminal unsuccessful stage.
- Deleting a non-terminal stage reassigns its tasks to the first available stage.

### Account and settings flow

- Profile and settings remain outside the primary task browsing loop.
- Auth may interrupt access to online-only features, but should not redefine offline task architecture.

## Widget UX contract

- Widgets are not a separate product flow. They are alternate entry points into the same task and filter architecture.
- Widget filters must map to the same filter definitions used by the main app.
- Opening the app from a widget should resolve into an existing task, filter, project, or board context rather than an undocumented special mode.
- If widgets require a new user flow or a new kind of context restoration, document that change here and in `docs/WIDGET_RULES.md`.

## Architectural implication

List and kanban are not separate products and not separate stores. They are two projections over one canonical task domain, enriched by project, board, and board-stage context.

## UI implementation rule

- MVP interface work should default to native platform components and standard interaction patterns.
- Shared UI abstractions should stay minimal until a repeated product need is proven across platforms.
- UX architecture changes must be documented here even if the final UI implementation uses native components only.
- List, board, settings, profile, auth, and widget-driven task entry surfaces should be reviewed against platform guidelines after UI changes.

## Documentation maintenance rule

- If implementation changes section boundaries, shell responsibilities, entry points, navigation flow, context restoration, widget-to-app behavior, page responsibilities, board-stage behavior, or flow integration rules, update this file in the same change.
- If implementation only changes visuals inside an existing UX contract, this file does not need to change.
- If a new platform adopts the same UX contract with platform-specific navigation patterns, document the platform-specific mapping in the nearest platform README and keep this file as the canonical product-level UX source.
