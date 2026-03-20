# MVP App Structure

## Goal

Define a canonical MVP-level application structure before detailed UI implementation starts.

## Core sections

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

## Section responsibilities

### Auth

- sign in for online features
- restore session
- gate server-backed collaboration and sync controls

### TaskList

- default task browsing surface
- dense scan of tasks
- quick navigation into task details
- filter application
- grouping and narrowing by project
- grouping and narrowing by board

### KanbanBoard

- alternate view over the same task set
- drag and drop between columns
- column definitions based on task state or grouping rules
- board-scoped view over tasks within a chosen project or board context

### TaskPage

- single-task editing
- metadata editing
- future collaboration context for a specific task
- links to owning project and board context when assigned

### Project

- task grouping at the product level
- high-level container for related work
- default scope for task browsing, filtering, and board organization

### Board

- grouping layer for tasks inside a project or another explicit scope
- owner of kanban-oriented organization
- source for board-specific views and future board settings

### Profile

- account identity
- future collaboration identity
- session-related profile info

### Settings

- theme selection
- app preferences
- future sync or debug preferences

## Canonical navigation model

The MVP should support:

- entering the task area as the main landing experience
- choosing or restoring a project context
- choosing a board context where relevant
- switching between list and kanban without changing the underlying task source
- opening a task page from either list or kanban
- accessing profile and settings from the shell level
- starting auth when online-only features are required

## Architectural implication

List and kanban are not separate products and not separate stores. They are two projections over one canonical task domain, enriched by project and board context.

## UI implementation rule

- MVP interface work should default to native platform components and standard interaction patterns.
- Shared UI abstractions should stay minimal until a repeated product need is proven across platforms.
- List, board, settings, profile, and auth surfaces should be reviewed against platform guidelines after UI changes.
