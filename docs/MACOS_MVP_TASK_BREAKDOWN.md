# macOS MVP Task Breakdown

## Purpose

This file is a working execution checklist for the first macOS vertical slice.

Use it as the operational task list for coding agents.

Rules:

- take one unchecked task or one small logical group of tasks at a time
- mark completed tasks in the same change where the implementation is finished
- if implementation changes architecture, data contracts, or flow rules, update the canonical docs in the same change
- do not use this file as a replacement for canonical architecture documents

Canonical references:

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/MVP_APP_STRUCTURE.md`
- `docs/TYPES_AND_CONTRACTS.md`
- `docs/SYNC_RULES.md`
- `docs/DEVELOPMENT_RULES.md`

## Phase 0. Bootstrap

- [x] Confirm active scope is macOS only
- [x] Confirm `Home` stays placeholder-only
- [x] Confirm no backend sync, auth, realtime push, widgets, or permissions are included
- [x] Confirm SQLite-backed local persistence is the Apple local storage baseline

### Phase 0 Review Tasks

- [x] Align `tooling/scripts/bootstrap_apple_xcode_projects.rb` with macOS-only scope for this phase (do not generate iOS by default during Phase 0)
- [x] Remove or isolate iOS bootstrap artifacts from Phase 0 delivery (`apple/ios/AltisIOS.xcodeproj`, `apple/ios/App/AltisIOSApp.swift`, `apple/ios/App/RootView.swift`, `apple/ios/Tests/AltisIOSTests.swift`)
- [x] Add explicit validation note for Phase 0 acceptance in this file (what was verified, when, and by which command or manual check)

### Phase 0 Validation Record

Verified: 2026-03-22

**Scope confirmation** — manual review of `AGENTS.md`, `docs/ARCHITECTURE.md`, `docs/MVP_APP_STRUCTURE.md`:
- Active scope confirmed as macOS-only vertical slice
- `Home` confirmed as placeholder-only with no live data
- Backend sync, auth, realtime push, widgets, and permissions confirmed out of scope
- SQLite-backed local persistence confirmed as the Apple local storage baseline

**Bootstrap script** — `tooling/scripts/bootstrap_apple_xcode_projects.rb`:
- Added `--platform` flag; default is now `macos` (Phase 0 safe)
- iOS generation requires explicit `--platform=ios` or `--platform=all`

**iOS artifact isolation** — manual `mv` + `rm`:
- `apple/ios/AltisIOS.xcodeproj` — deleted (regenerable via `--platform=ios`)
- `apple/ios/App/AltisIOSApp.swift` → `apple/ios/_phase0_deferred/App/`
- `apple/ios/App/RootView.swift` → `apple/ios/_phase0_deferred/App/`
- `apple/ios/Tests/AltisIOSTests.swift` → `apple/ios/_phase0_deferred/Tests/`

**macOS project** — verified present and unmodified at `apple/macos/AltisMacOS.xcodeproj`

## Phase 1. App Structure

- [x] Create `apple/macos/App/Shell/`
- [x] Create `apple/macos/App/Navigation/`
- [x] Create `apple/macos/App/Features/Home/`
- [x] Create `apple/macos/App/Features/Project/`
- [x] Create `apple/macos/App/Features/Board/`
- [x] Create `apple/macos/App/Features/TaskList/`
- [x] Create `apple/macos/App/Features/KanbanBoard/`
- [x] Create `apple/macos/App/Features/TaskPage/`
- [x] Create feature-local `Page/`, `Components/`, `State/`, and `Utilities/` directories only where needed
- [x] Keep all new UI code at `platform app` level unless real shared reuse is proven

### Phase 1 Validation Record

Verified: 2026-03-22

**Directory structure created** — all directories added under `apple/macos/App/`:
- `Shell/` — `AppShell.swift` (structural `NavigationSplitView` shell, placeholder sidebar + detail)
- `Navigation/` — `AppRoute.swift` (typed `AppRoute` enum, placeholder for Phase 4 expansion)
- `Features/Home/Page/` — `HomePageView.swift` (placeholder `ContentUnavailableView`)
- `Features/Home/State/` — `HomeFeatureState.swift` (empty struct, no live data per Phase 5 constraint)
- `Features/Project/Page/` — `ProjectPageView.swift`
- `Features/Project/State/` — `ProjectFeatureState.swift`
- `Features/Board/Page/` — `BoardPageView.swift`
- `Features/Board/State/` — `BoardFeatureState.swift`
- `Features/TaskList/Page/` — `TaskListPageView.swift`
- `Features/TaskList/State/` — `TaskListFeatureState.swift`
- `Features/KanbanBoard/Page/` — `KanbanBoardPageView.swift`
- `Features/KanbanBoard/State/` — `KanbanBoardFeatureState.swift`
- `Features/TaskPage/Page/` — `TaskPageView.swift`
- `Features/TaskPage/State/` — `TaskPageFeatureState.swift`

**Ownership** — all files at `platform app` level (`apple/macos`), no shared promotion.

**Wiring** — `RootView` updated to render `AppShell`. `AltisMacOSApp` entry point unchanged.

**Build** — project built successfully with zero errors after all changes.

## Phase 2. Typed Models

- [ ] Implement typed identifier strategy for canonical entities
- [ ] Implement `Workspace`
- [ ] Implement `Project`
- [ ] Implement `Board`
- [ ] Implement `BoardStage`
- [ ] Implement `BoardStagePreset`
- [ ] Implement `BoardStagePresetStage`
- [ ] Implement `Task`
- [ ] Implement `SyncMetadata`
- [ ] Encode board-stage invariants in model or domain validation

## Phase 3. Persistence

- [ ] Define SQLite-backed local persistence interfaces in `shared/persistence/`
- [ ] Define persistence records for `Project`
- [ ] Define persistence records for `Board`
- [ ] Define persistence records for `BoardStage`
- [ ] Define persistence records for `BoardStagePreset`
- [ ] Define persistence records for `Task`
- [ ] Define local sync metadata persistence shape
- [ ] Define local-first write path contract
- [ ] Ensure UI read models come from local persistence-backed projections

## Phase 4. Application Layer

- [ ] Define feature flow contract for `Home`
- [ ] Define feature flow contract for `Project`
- [ ] Define feature flow contract for `Board`
- [ ] Define feature flow contract for `TaskList`
- [ ] Define feature flow contract for `KanbanBoard`
- [ ] Define feature flow contract for `TaskPage`
- [ ] Define isolated data worker or service interfaces for persistence access
- [ ] Define typed events for user intents
- [ ] Define typed state for each feature
- [ ] Ensure initial data ingress and later updates enter the same flow structure

## Phase 5. Home

- [ ] Implement placeholder-only `HomeShell`
- [ ] Add placeholder entry point for dashboards
- [ ] Add placeholder entry point for projects
- [ ] Add placeholder entry point for boards
- [ ] Ensure `Home` does not load live project, board, task, or dashboard data

## Phase 6. Project Flow

- [ ] Implement create project flow
- [ ] Implement project list projection
- [ ] Implement navigation from `Home` into project-related flow
- [ ] Persist created projects locally

## Phase 7. Board Flow

- [ ] Implement create board flow
- [ ] Implement create board from preset copy
- [ ] Ensure board creation always results in at least three stages
- [ ] Ensure exactly one terminal success stage exists
- [ ] Ensure exactly one terminal failure stage exists
- [ ] Implement board list projection
- [ ] Persist created boards locally

## Phase 8. Board Stage Management

- [ ] Implement add stage to end
- [ ] Implement rename stage
- [ ] Implement delete non-terminal stage
- [ ] Reassign tasks from deleted stage to first available stage
- [ ] Prevent deletion of terminal stages
- [ ] Allow rename of terminal stages
- [ ] Persist stage order changes locally

## Phase 9. Task Creation And Detail

- [ ] Implement create task flow
- [ ] Assign task to project
- [ ] Assign task to board when board context is active
- [ ] Assign task to stage when board workflow is active
- [ ] Implement `TaskPage`
- [ ] Show current stage in task detail
- [ ] Show compact stage progress line in task detail
- [ ] Persist tasks locally

## Phase 10. Task List

- [ ] Implement `TaskList` page
- [ ] Show task title
- [ ] Show current stage in list mode
- [ ] Support opening `TaskPage` from list
- [ ] Ensure list reads from local typed projections only

## Phase 11. Kanban

- [ ] Implement `KanbanBoard` page
- [ ] Group tasks by current stage
- [ ] Render stage columns in order
- [ ] Render task cards with compact stage-progress line
- [ ] Support opening `TaskPage` from kanban card
- [ ] Ensure kanban reads from local typed projections only

## Phase 12. Drag And Drop

- [ ] Implement drag source for task cards
- [ ] Implement drop target for stage columns
- [ ] Update task stage through event flow, not direct view mutation
- [ ] Persist stage movement locally
- [ ] Re-render list, task detail, and kanban from updated local projections

## Phase 13. Terminal Actions

- [ ] Add complete action on task card
- [ ] Add fail action on task card
- [ ] Add complete action on task page
- [ ] Add fail action on task page
- [ ] Move task into terminal success stage on complete
- [ ] Move task into terminal failure stage on fail
- [ ] Ensure terminal actions stay consistent across list, card, and detail projections

## Phase 14. Validation

- [ ] Run fast diagnostics for touched Swift files
- [ ] Build the macOS project when buildable
- [ ] Fix actionable compiler errors
- [ ] Fix actionable warnings that reflect real issues
- [ ] Document any validation limitation if full build cannot run

## Phase 15. Documentation Sync

- [ ] Update canonical docs if model meanings changed
- [ ] Update canonical docs if flow boundaries changed
- [ ] Update canonical docs if persistence conventions changed
- [ ] Update canonical docs if a component moved to a wider ownership level
- [ ] Mark completed tasks in this file

## Definition Of Done For First Vertical Slice

- [ ] `Home` opens as placeholder-only landing hub
- [ ] User can create a project
- [ ] User can create a board
- [ ] User can create a board from preset copy
- [ ] Board preserves valid stage invariants
- [ ] User can create a task
- [ ] List shows current stage
- [ ] Kanban groups tasks by stage
- [ ] Drag-and-drop moves tasks between stage columns
- [ ] Complete moves a task to terminal success stage
- [ ] Fail moves a task to terminal failure stage
- [ ] Local state survives restart
- [ ] Relevant docs remain in sync with implementation
