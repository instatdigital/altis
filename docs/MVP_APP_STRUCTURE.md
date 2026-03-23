# MVP App Structure

## Goal

Define a canonical MVP-level application structure before detailed UI implementation starts.

This file is the source of truth for UX-level application architecture in the current phase. It describes sections, user flows, screen responsibilities, and interaction boundaries without locking the project to a visual design system.

## UX architecture principles

- UX architecture should be documented in terms of sections, flows, responsibilities, and state transitions.
- Agents must not invent new sections, navigation branches, or feature entry points unless those changes are added to this file in the same change.
- Pages, layouts, and reusable visual components MUST be documented as part of an event-driven flow, not as isolated visual fragments.
- Board mode choice is a UX-level concern because it changes data authority and availability for the selected board without changing the overall shell structure.

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
- offline boards
- online boards
- online authorization for server-backed features

## UX responsibilities by section

### Auth

- sign in for online boards and other server-backed features
- restore session
- gate server-backed collaboration and account features
- return the user into the previously relevant online flow when possible

### Home

- canonical landing surface before detailed project and board work
- provide normal entry points into projects and boards
- host placeholder dashboard content during early MVP
- remain placeholder-only in the first vertical slice

### TaskList

- default task browsing surface
- dense scan of tasks
- quick navigation into task details
- filter application
- grouping and narrowing by project
- grouping and narrowing by board
- show the task's current board stage when a board context is active

### KanbanBoard

- alternate view over the same task set
- drag and drop between stage columns
- board-scoped view over tasks within a chosen project or board context
- visual workflow management over the same canonical task source

### TaskPage

- single-task editing
- metadata editing
- links to owning project and board context when assigned
- canonical detail surface opened from list, board, widgets, or future search results
- show compact progress through board stages when the task belongs to a staged board
- provide explicit actions to complete or close unsuccessfully when the task belongs to a staged board

### Project

- task grouping at the product level
- high-level container for related work
- stable context switch for list and board projections

### Board

- owner of kanban-oriented organization
- owner of ordered board stages
- owner of terminal successful and terminal unsuccessful stages
- owner of the board mode choice: `offline` or `online`
- may be created from reusable stage presets

### Profile

- account identity
- future collaboration identity
- session-related profile info

### Settings

- theme selection
- app preferences
- device-level options

## Canonical UX shells

The MVP should be understood as a small number of stable UX shells:

- `HomeShell`: landing area for dashboards and board-entry choices
- `HomeShell` does not split into separate offline and online branches
- `TaskShell`: the main work area for task browsing and switching between list and kanban
- `ContextShell`: project and board selection or restoration around the same task source
- `TaskDetailFlow`: entry into a single task and return to the previous task context
- `BoardConfigurationFlow`: board stage editing and board creation from stage presets
- `AccountShell`: profile, settings, and auth-related flows

## Typed data contract

- UI data MUST be typed and consistent with shared domain meaning and read models.
- Offline board pages and components MUST render from local typed projections.
- Online board pages and components MUST render from typed feature state or explicit online read models.
- Board-owned task and stage surfaces inherit their data authority from the selected board.
- Board mode choice belongs to board creation, not to top-level shell switching or later board configuration.
- Components SHOULD receive only the data required for rendering and interaction.

## Event-driven flow contract

The project uses an event-driven application model analogous to BLoC.

Required responsibilities:

- components emit user intents as typed events
- pages subscribe to the flows relevant to the surface they compose
- feature flows process user, lifecycle, and online result events
- feature flows work through isolated data-facing classes for local persistence or online transport
- local or online state changes drive rendering according to board mode

UI MUST NOT hide the difference between offline and online boards inside board-specific flows.

## Board stage UX contract

- staged boards use one ordered stage sequence shared by list, task detail, and kanban views
- every staged board preserves at least three stages: one ordinary stage, one terminal successful stage, and one terminal unsuccessful stage
- list mode shows the task's current stage
- task cards show a compact stage-progress line with the current stage
- kanban mode groups cards by current stage
- task cards and task pages expose an explicit complete action that moves the task to the terminal successful stage
- task cards and task pages expose an explicit close-unsuccessfully action that moves the task to the terminal unsuccessful stage
- boards may be created from reusable stage presets
- board creation copies a preset into board-local stage definitions

## Canonical navigation model

The MVP should support:

- entering the app through the homepage
- choosing or restoring a project context
- choosing a board context where relevant
- switching between list and kanban without changing the underlying task source
- opening a task page from either list or kanban
- accessing board configuration for stage setup when permitted
- accessing profile and settings from the shell level
- starting auth when online-only features are required
- choosing board mode when creating a board

## UX flow contracts

### Board selection flow

- The user enters the app through `Home`.
- The app keeps one normal navigation shell for projects and boards.
- Entering an existing board uses that board's stored mode.
- Creating a board requires choosing whether that board is offline or online.

### Task browsing flow

- The user enters the task area.
- The app restores or selects project context.
- The app restores or selects board context when relevant.
- The user browses tasks in list or kanban mode over the same canonical task source.
- Opening a task moves the user into `TaskDetailFlow` without breaking the surrounding context.

### Task detail flow

- A task may be opened from list, kanban, widgets, and future task-oriented entry points.
- The detail surface edits the same canonical task entity.
- Leaving task detail should return the user to the originating context whenever possible.

### Context switching flow

- Project changes redefine the active task scope.
- Board changes refine the active projection inside the current or explicit project scope.
- Entering a different board may change data authority and permitted actions if that board has a different mode.

### Account and settings flow

- Profile and settings remain outside the primary task browsing loop.
- Auth may interrupt access to online-only features, but should not redefine offline-board architecture.

## Widget UX contract

- Widgets are not a separate product flow.
- Widget filters must map to the same filter definitions used by the main app.
- Opening the app from a widget should resolve into an existing task, filter, project, or board context rather than an undocumented special mode.

## Architectural implication

List and kanban are not separate products and not separate stores. They are two projections over one canonical task domain. The important architectural split is board authority, and that split lives on `Board`, not in a separate shell.

## Documentation maintenance rule

- If implementation changes section boundaries, shell responsibilities, entry points, navigation flow, board-mode choice, page responsibilities, or flow integration rules, update this file in the same change.
