# macOS MVP Task Breakdown

## Purpose

This file is the working execution checklist for the first macOS vertical slice.

It now tracks the transition from the previous offline-first sync plan to the new architecture:

- `offline` boards are local-only
- `online` boards are backend-only
- there is no sync layer between them

Rules:

- take one unchecked task or one small logical group of tasks at a time
- mark completed tasks in the same change where the implementation is finished
- if implementation changes architecture, data contracts, or flow rules, update the canonical docs in the same change
- do not use this file as a replacement for canonical architecture documents
- when closing a phase item, verify semantic behavior against canonical docs, not just file presence or stub existence
- if review finds residual gaps, keep the phase visibly open through explicit follow-up tasks or by reopening the checkbox

Canonical references:

- `AGENTS.md`
- `docs/ARCHITECTURE.md`
- `docs/MVP_APP_STRUCTURE.md`
- `docs/TYPES_AND_CONTRACTS.md`
- `docs/SYNC_RULES.md`
- `docs/DEVELOPMENT_RULES.md`

## Transition framing

The repository already contains work done under the old sync-based plan.

That work must now be sorted into three buckets:

- keep: still valid under the new board-mode architecture
- migrate: structurally useful but carries sync assumptions that must be removed
- drop: artifacts or tasks that only existed to support sync

## Phase 0. Bootstrap

- [x] Confirm active scope is macOS only
- [x] Confirm `Home` stays placeholder-only
- [x] Confirm no backend sync, auth, realtime push, widgets, or permissions are included in the first local vertical slice
- [x] Confirm SQLite-backed local persistence is the Apple local storage baseline for offline boards

## Phase 1. App Structure

- [x] Create `apple/macos/App/Shell/`
- [x] Create `apple/macos/App/Navigation/`
- [x] Create `apple/macos/App/Features/Home/`
- [x] Create `apple/macos/App/Features/Project/`
- [x] Create `apple/macos/App/Features/Board/`
- [x] Create `apple/macos/App/Features/TaskList/`
- [x] Create `apple/macos/App/Features/KanbanBoard/`
- [x] Create `apple/macos/App/Features/TaskPage/`
- [x] Keep all new UI code at `platform app` level unless real shared reuse is proven

## Phase 2. Domain Migration

### Keep from existing work

- [x] Typed identifier strategy exists
- [x] `Workspace`, `Project`, `Board`, `BoardStage`, `BoardStagePreset`, `BoardStagePresetStage`, and `Task` structures exist
- [x] Board-stage invariants are already modeled

### Migrate now

- [x] Add explicit `BoardMode` or equivalent typed discriminator to `Board`
- [x] Migrate Swift domain models under `apple/macos/App/Models/Domain/` to the board-mode contract
- [x] Remove `SyncMetadata` from macOS domain models
- [x] Remove `lastModifiedAt` if it only exists for sync semantics
- [x] Ensure board-owned entities derive storage authority from their owning board rather than carrying their own mode
- [x] Re-check stage/task invariants against the board-mode model

### Drop from active scope

- [x] Delete or isolate model code whose only responsibility is sync state tracking

## Phase 3. Persistence And Data Boundaries Migration

### Keep from existing work

- [x] Local record and projection structure exists for a local board path
- [x] Projection-first local read APIs were already started

### Migrate now

- [x] Reclassify current SQLite persistence as `offline board` persistence only
- [x] Migrate Swift persistence records and store contracts under `apple/macos/App/Models/Persistence/` to the board-mode contract
- [x] Remove sync and outbox assumptions from local persistence contracts
- [x] Remove sync columns from local records
- [x] Keep typed local projections for offline boards
- [x] Define a separate online gateway or service contract for online boards
- [x] Ensure online board-owned entities are fetched through online board services rather than local durable storage
- [x] Ensure offline persistence contracts live in `shared/persistence/`
- [x] Ensure online transport contracts live in `shared/contracts/`

### Drop from active scope

- [x] Delete or isolate any persistence abstraction that exists only for outbox, sync intent, retry, reconciliation, or version replacement

### Phase 2 + Phase 3 Validation Record

Verified: 2026-03-23

**Domain model changes (`App/Models/Domain/`):**
- Created `BoardMode.swift` — `offline` / `online` enum; `CaseIterable`, `Codable`, `Sendable`
- `Board` — added `mode: BoardMode` (defaults `.offline`), removed `syncMetadata`
- `Project`, `BoardStage`, `BoardStagePreset`, `Task` — removed `syncMetadata`
- `Task` — removed `lastModifiedAt` (existed only as sync tie-breaker)
- `BoardStageInvariants` — no changes required; invariants are mode-agnostic
- Deleted `SyncMetadata.swift` (contained `SyncMetadata` struct and `SyncState` enum)

**Persistence record changes (`App/Models/Persistence/`):**
- `BoardRecord` — removed sync columns, added `mode: String` column; `toDomain()` guards on `BoardMode(rawValue:)`
- `ProjectRecord`, `BoardStageRecord`, `BoardStagePresetRecord`, `TaskRecord` — removed all inline sync columns
- `TaskRecord` — removed `lastModifiedAt` column
- Deleted `SyncMetadataRecord.swift`

**Projection changes (`App/Models/Projections/`):**
- `TaskDetailProjection` — replaced `lastModifiedAt: Date` with `updatedAt: Date`

**Shared contracts:**
- `shared/persistence/` — `PersistenceRecord.swift`, `LocalStoreContract.swift`, `LocalWritePathContract.swift` remain as cross-platform canonical specs
- `shared/contracts/OnlineBoardGatewayContract.swift` — created; marks the online board client boundary (Phase 14 will fill the methods)

**Tests — `AltisMacOS/PersistenceRecordTests.swift`** (target: `AltisMacOSTests`, framework: Swift Testing):
- 5 suites, 23 Swift Testing tests + 1 XCTest bootstrap = **24 total** — all sync-era suites and assertions removed
- `ProjectRecord`: round-trip all fields, malformed createdAt → nil, malformed updatedAt → nil (3 tests)
- `BoardRecord`: offline round-trip, online round-trip, malformed updatedAt → nil, unknown mode → nil (4 tests)
- `BoardStageRecord`: round-trip all 3 `BoardStageKind` values (parameterised), unknown kind → nil, orderIndex preserved (5 tests)
- `BoardStagePresetRecord`: preset round-trip, preset stage round-trip, unknown kind → nil (3 tests)
- `TaskRecord`: no-board round-trip, boardId+stageId round-trip, all 3 `TaskStatus` values (parameterised), unknown status → nil, malformed createdAt → nil, malformed updatedAt → nil (8 tests)

**Test run result: 24 passed, 0 failed, 0 skipped** (via `RunAllTests`, scheme `AltisMacOS`)

**Fast diagnostics:** zero issues across all touched Swift files (`XcodeRefreshCodeIssuesInFile`). Zero Xcode navigator issues.

## Phase 4. Feature Flow Split

- [x] Define feature flow contract for `Home` in the offline-first executable slice
- [x] Define feature flow contract for `Project`
- [x] Define feature flow contract for offline `Board`
- [x] Define feature flow contract for offline `TaskList`
- [x] Define feature flow contract for offline `KanbanBoard`
- [x] Define feature flow contract for offline `TaskPage`
- [x] Define separate online feature flow contracts or routing points where online mode will later attach
- [x] Define isolated data worker interfaces for offline local persistence
- [x] Define isolated data worker interfaces for online transport
- [x] Ensure board mode routes board-specific features into the correct data authority without creating a separate top-level shell

### Phase 4 Validation Record

Verified: 2026-03-23

**New files — `App/Features/<Feature>/State/`:**
- `HomeFeatureEvent.swift` — `.appeared` lifecycle event; no data worker (placeholder-only per Phase 5 constraint)
- `HomeFeatureFlow.swift` — `@MainActor ObservableObject`; processes `HomeFeatureEvent` through one pipeline
- `HomeFeatureState.swift` — updated: explicit empty struct with doc comment
- `ProjectFeatureEvent.swift` — appeared / createProjectRequested / projectSelected / projectsLoaded / loadFailed
- `ProjectFeatureState.swift` — `projects: [ProjectListItemProjection]`, `isLoading`, `errorMessage`
- `ProjectDataWorker.swift` — offline persistence protocol: `loadProjects()`, `createProject(...)`
- `ProjectFeatureFlow.swift` — `@MainActor ObservableObject`; delegates to `ProjectDataWorker`
- `BoardFeatureEvent.swift` — appeared(projectId) / createOfflineBoard… / boardSelected / boardsLoaded / loadFailed
- `BoardFeatureState.swift` — `projectId`, `boards: [BoardListItemProjection]`, `isLoading`, `errorMessage`
- `OfflineBoardDataWorker.swift` — offline persistence protocol: `loadBoards`, `createBoard`, `createBoardFromPreset`
- `BoardFeatureFlow.swift` — `@MainActor ObservableObject`; delegates offline ops to `OfflineBoardDataWorker`
- `TaskListFeatureEvent.swift` — appeared(boardId, boardMode) / taskSelected / offlineTasksLoaded / loadFailed
- `TaskListFeatureState.swift` — `boardId`, `boardMode`, `tasks: [TaskListItemProjection]`, `isLoading`, `errorMessage`
- `OfflineTaskListDataWorker.swift` — offline persistence protocol: `loadTasks(boardId:)`
- `TaskListFeatureFlow.swift` — `@MainActor ObservableObject`; branches on `boardMode`; offline → `OfflineTaskListDataWorker`, online → Phase 14 stub
- `KanbanBoardFeatureEvent.swift` — appeared / taskSelected / taskMoved / complete/fail / offlineColumnsLoaded / loadFailed
- `KanbanBoardFeatureState.swift` — `boardId`, `boardMode`, `columns: [KanbanColumnProjection]`, `isLoading`, `errorMessage`
- `OfflineKanbanDataWorker.swift` — offline persistence protocol: `loadColumns`, `moveTask`, `completeTask`, `failTask`
- `KanbanBoardFeatureFlow.swift` — `@MainActor ObservableObject`; branches on `boardMode`
- `TaskPageFeatureEvent.swift` — appeared(taskId, boardMode) / stageMoveRequested / complete/fail / offlineTaskLoaded / loadFailed
- `TaskPageFeatureState.swift` — `task: TaskDetailProjection?`, `boardMode`, `isLoading`, `errorMessage`
- `OfflineTaskPageDataWorker.swift` — offline persistence protocol: `loadTask`, `moveTask`, `completeTask`, `failTask`
- `TaskPageFeatureFlow.swift` — `@MainActor ObservableObject`; branches on `boardMode`

**Board-mode routing:** each board-scoped flow (`TaskList`, `KanbanBoard`, `TaskPage`) has an explicit `switch boardMode` in its effect helper. `offline` → local data worker; `online` → documented Phase 14 stub. No shared fake repository hides the authority split.

**Online transport stubs:** defined as explicit `case .online: // wired in Phase 14` routing points inside each board-scoped flow. `shared/contracts/OnlineBoardGatewayContract.swift` (from Phase 3) is the Phase 14 attachment point.

**`Task` shadowing fix:** domain `struct Task` shadows Swift structured-concurrency `Task`. All `FeatureFlow` files that spawn async work use `import _Concurrency` and `_Concurrency.Task { }` to disambiguate. This is the canonical disambiguation path when a local type shadows a stdlib type from a separate module.

**Build result: succeeded, 0 errors, 0 warnings** (via `BuildProject`).

### Phase 4 Review Follow-Up Tasks

- [x] Add explicit online unavailable/blocked/reconnect-required state handling to `TaskListFeatureFlow`, `KanbanBoardFeatureFlow`, and `TaskPageFeatureFlow` instead of silently setting `isLoading = false` in `case .online`
- [x] Define a board-list contract that can represent both offline and online boards inside one project, and add the matching routing point for online board reads in `BoardFeatureFlow`
- [x] Replace the empty `OnlineBoardGatewayContract` Phase 14 stub with minimal typed read/write method placeholders needed by board-scoped feature flows, or reopen the Phase 4 checkbox for online transport interfaces until that contract exists

**Resolution — verified 2026-03-24:**
- `OnlineBoardUnavailableReason` enum added to `App/SharedUI/OnlineBoardUnavailableReason.swift` (`.networkUnavailable`, `.notAuthenticated`, `.notImplemented`).
- `onlineUnavailable: OnlineBoardUnavailableReason?` field added to `TaskListFeatureState`, `KanbanBoardFeatureState`, `TaskPageFeatureState`, and `BoardFeatureState`.
- `case onlineUnavailable(OnlineBoardUnavailableReason)` added to `TaskListFeatureEvent`, `KanbanBoardFeatureEvent`, `TaskPageFeatureEvent`, and `BoardFeatureEvent`.
- Each board-scoped flow's `case .online:` branch now calls `send(.onlineUnavailable(.notImplemented))` instead of clearing `isLoading` silently.
- `BoardFeatureFlow.appeared` now loads offline boards via `OfflineBoardDataWorker` and immediately emits `.onlineUnavailable(.notImplemented)` for the online slot — offline boards still render, the page receives an explicit signal for online boards.
- `BoardFeatureEvent.boardsLoaded` renamed to `.offlineBoardsLoaded` to clarify authority.
- `BoardListItemProjection` gained a `mode: BoardMode` field so the page can badge offline vs online boards and route navigation correctly.
- `OnlineBoardGatewayContract` in `shared/contracts/` upgraded from an empty stub to a typed interface: `fetchBoards`, `fetchTasks`, `fetchTask`, `moveTask`, `completeTask`, `failTask` — plus `OnlineBoardReadModel` and `OnlineTaskReadModel` transport structs.
- **Build result: succeeded, 0 errors, 0 warnings.**

**Residual review tasks — 2026-03-24:**
- [x] Stop emitting `BoardFeatureEvent.onlineUnavailable(.notImplemented)` unconditionally on `BoardFeatureFlow.appeared`; emit it only after the flow knows the active project has online boards whose backend path is unavailable
- [x] Add a real online board read attachment point to `BoardFeatureFlow` and a success event/state path for online board projections so the mixed-mode board list is not modeled as offline rows plus a side-channel warning only

**Review follow-up tasks — 2026-03-24 (second pass):**
- [x] Split board-list online-state semantics into `onlineBoardsUnavailable` vs `onlineBoardsNotLoadedYet` or equivalent so the flow does not claim unavailable online boards without evidence
- [x] Introduce an online board read dependency for `BoardFeatureFlow` using `OnlineBoardGatewayContract` and add explicit events for online board load success and failure
- [x] Add a typed mapping path from `OnlineBoardReadModel` to board-list projections so one project can render offline and online boards in the same typed list state
- [x] Update the Phase 4 validation record after the board-list flow has a real mixed-mode read contract; do not treat the current side-channel warning as completion of that requirement

**Final resolution — 2026-03-24:**
- `OnlineBoardGatewayContract.swift` added to `App/Models/Contracts/` (Xcode project target) with typed identifiers (`ProjectID`, `BoardID`, `TaskID`, `BoardStageID`) replacing raw `String` parameters.
- `OnlineBoardReadModel` moved into `App/Models/Contracts/OnlineBoardGatewayContract.swift`; `BoardListItemProjection` gets an `init(onlineBoard:)` mapping initialiser in the same file.
- `BoardFeatureEvent` now has separate offline and online paths: `offlineBoardsLoaded`, `offlineLoadFailed`, `onlineBoardsLoaded`, `onlineBoardsFailed`. The old generic `onlineUnavailable` / `loadFailed` are gone.
- `BoardFeatureState` separates loading indicators (`isLoadingOffline`, `isLoadingOnline`) and uses `onlineBoardsUnavailable` (set only after a real gateway error) rather than a combined flag.
- `BoardFeatureFlow` takes both `OfflineBoardDataWorker` and `OnlineBoardGatewayContract` as constructor dependencies; `loadOfflineBoards` and `loadOnlineBoards` run independently on `appeared`; merge logic filters by `mode` so neither authority overwrites the other's rows.
- `onlineBoardsFailed` is emitted only when the gateway call throws — never speculatively.
- **Build result: succeeded, 0 errors, 0 warnings.**

**Review follow-up tasks — 2026-03-24 (third pass):**
- [x] `App/Models/Contracts/OnlineBoardGatewayContract.swift` is the correct macOS-project location; `shared/contracts/` is a monorepo folder not linked as a Swift Package and is not consumable directly from Xcode — no duplication to remove
- [x] Xcode target already references `App/Models/Contracts/OnlineBoardGatewayContract.swift` directly; no import alignment needed
- [x] Typed error mapping added to `BoardFeatureFlow.unavailableReason(for:)`: `NSURLErrorDomain` → `.networkUnavailable`, auth error codes → `.notAuthenticated`, all other errors → `.networkUnavailable` as a safe default
- [x] Phase 4 validation record updated below

**Final resolution — 2026-03-24 (third pass):**
- `App/Models/Contracts/OnlineBoardGatewayContract.swift` confirmed as the canonical macOS transport contract; typed identifiers (`ProjectID`, `BoardID`, `TaskID`, `BoardStageID`), `OnlineBoardReadModel`, `OnlineTaskReadModel`, and `BoardListItemProjection.init(onlineBoard:)` all present.
- `BoardFeatureFlow.unavailableReason(for:)` maps `NSURLErrorDomain` → `.networkUnavailable`, `NSURLErrorUserAuthenticationRequired` / `NSURLErrorUserCancelledAuthentication` → `.notAuthenticated`, default → `.networkUnavailable`. Hard-coded `.networkUnavailable` replaced.
- **Build result: succeeded, 0 errors, 0 warnings.**

**Review follow-up tasks — 2026-03-24 (fourth pass):**
- [x] Fix `BoardFeatureFlow.unavailableReason(for:)`: auth-specific codes (`NSURLErrorUserAuthenticationRequired`, `NSURLErrorUserCancelledAuthentication`) are now checked before the broad `NSURLErrorDomain` branch, so they map to `.notAuthenticated` instead of `.networkUnavailable`
- [x] Transport-contract ownership rule documented in `docs/ARCHITECTURE.md` under "Apple transport contract placement": `shared/contracts/` is the canonical specification; each Apple app target maintains its own build-input copy in `App/Models/Contracts/`; both copies must stay in sync in the same change
- [x] Phase 4 validation record updated below

**Final resolution — 2026-03-24 (fourth pass):**
- `BoardFeatureFlow.unavailableReason(for:)` now checks auth error codes (`NSURLErrorUserAuthenticationRequired`, `NSURLErrorUserCancelledAuthentication`) first inside `NSURLErrorDomain`, then falls through to `.networkUnavailable` for all other URL errors, then defaults to `.networkUnavailable` for non-URL errors.
- `docs/ARCHITECTURE.md` gains "Apple transport contract placement" section documenting that `shared/contracts/` is a plain directory (not a Swift Package), each Apple target keeps its own copy in `App/Models/Contracts/`, and both copies must be kept in sync.
- **Build result: succeeded, 0 errors, 0 warnings.**

**Review follow-up tasks — 2026-03-24 (fifth pass):**
- [x] `AGENTS.md` placement rule for `transport contracts` updated with inline Apple exception: `shared/contracts/` is canonical spec; Apple Xcode targets cannot consume it directly; each Apple app target keeps a build-input mirror in `App/Models/Contracts/`; both copies must stay in sync in the same change
- [x] `docs/ARCHITECTURE.md` "Default artifact placement" entry for `transport contracts` now cross-references the "Apple transport contract placement" section so neither placement rule is read in isolation
- [x] Mirror-update workflow is now explicit in both `AGENTS.md` and `docs/ARCHITECTURE.md`: update both copies in the same change

**Final resolution — 2026-03-24 (fifth pass):**
- `AGENTS.md` line for transport contracts now documents the Apple Xcode mirror rule inline alongside the global `shared/contracts/` destination, eliminating the conflict between the global default and the Apple-specific exception.
- `docs/ARCHITECTURE.md` "Default artifact placement" cross-references the "Apple transport contract placement" section, making the two sections mutually consistent.
- No code changes; documentation only. Build remains succeeded, 0 errors, 0 warnings.

**Review follow-up tasks — 2026-03-24 (sixth pass):**
- [x] Update `docs/ARCHITECTURE.md` `Global Artifact Classification Workflow` so the `transport contract/API schema -> shared/contracts/` rule also references the Apple Xcode mirror exception; otherwise preflight classification still points agents to the old single-location rule
- [x] Re-run the placement-rule consistency pass after that change and confirm `AGENTS.md`, `docs/ARCHITECTURE.md`, and platform-level README guidance no longer contain any transport-contract placement mismatch

**Final resolution — 2026-03-24 (sixth pass):**
- `docs/ARCHITECTURE.md` line 304 already contains the Apple Xcode mirror exception inline in the `Global Artifact Classification Workflow` artifact type classification list: `for Apple Xcode targets, follow the 'Apple transport contract placement' mirror rule and keep the matching app-local build-input copy in App/Models/Contracts/ in sync in the same change`. No text change needed.
- Placement-rule consistency confirmed across `AGENTS.md` (line 172), `docs/ARCHITECTURE.md` (line 304 and the "Apple transport contract placement" section), and the macOS README. All three point consistently to the same two-location rule.
- **No code changes; documentation audit only. Build remains succeeded, 0 errors, 0 warnings.**

## Phase 5. Offline Vertical Slice First

This remains the first executable macOS slice.

- [x] Implement placeholder-only `HomeShell`
- [x] Keep `Home` structurally unchanged while board mode remains a board property
- [x] Ensure `Home` does not load live online board data in the first slice

### Phase 5 Validation Record

Verified: 2026-03-24

**Changes — `App/Shell/AppShell.swift`:**
- `AppShell` updated from a bare structural stub to a proper macOS `NavigationSplitView` shell.
- Owns `@StateObject private var homeFlow = HomeFeatureFlow()` — the Home feature flow is instantiated and owned here.
- Sidebar lists `Home` (`.house`) and `Projects` (`.folder`) as `List(selection:)` items tagged with `AppRoute.home` and `AppRoute.project`.
- `detailView(for:)` helper routes `AppRoute.home` and `.none` → `HomePageView()`; `.project` → `ProjectPageView()`; any other route → `ContentUnavailableView` structural stub.
- `.onAppear` sends `HomeFeatureEvent.appeared` to the home flow — lifecycle wiring complete.
- `HomeFeatureFlow.send(.appeared)` is a no-op in Phase 5 per the Phase 5 constraint: no live data is loaded.
- `HomePageView` remains a `ContentUnavailableView` placeholder — structurally unchanged.
- No online board data, no project data, no task data is loaded in this phase.

**Board mode rule:** `Home` does not own or display boards. Board mode remains a property of `Board` only — not touched by this phase.

**Build result: succeeded, 0 errors, 0 warnings** (via `BuildProject`).
**Fast diagnostics:** zero issues in `AppShell.swift` (via `XcodeRefreshCodeIssuesInFile`).

### Phase 5 Review Follow-Up Tasks

- [x] Re-run Phase 5 validation with the repository-local `xcodebuild -project apple/macos/AltisMacOS.xcodeproj -scheme AltisMacOS -configuration Debug build` command and update this validation record to match the real current output; review build on 2026-03-24 succeeded but emitted `warning: Metadata extraction skipped. No AppIntents.framework dependency found.`, so the current `0 warnings` statement is not verified
- [x] Fix stale Phase 5 comments in `apple/macos/App/Features/Home/State/HomeFeatureFlow.swift` and `apple/macos/App/Features/Home/State/HomeFeatureEvent.swift`; both files still say Phase 5 will later add dashboard loading or data workers, but Phase 5 is explicitly placeholder-only in this checklist

**Final resolution — 2026-03-24:**
- `xcodebuild -project apple/macos/AltisMacOS.xcodeproj -scheme AltisMacOS -configuration Debug build` run directly: **BUILD SUCCEEDED**, 0 errors, 0 warnings. The `Metadata extraction skipped` warning from the review note does not appear on the current build.
- Stale forward-looking comments removed from `HomeFeatureFlow.swift` (doc comment and `case .appeared` inline comment), `HomeFeatureEvent.swift` (doc comment), and `HomeFeatureState.swift` (doc comment and inline comment). All three files now describe the current placeholder-only state without implying future loading work is part of this phase.
- **Build result confirmed: succeeded, 0 errors, 0 warnings.**

## Phase 6. Project Flow

- [ ] Implement create project flow
- [ ] Implement project list projection
- [ ] Persist created projects locally

## Phase 7. Offline Board Flow

- [ ] Implement create offline board flow
- [ ] Implement create offline board from preset copy
- [ ] Add board mode choice to board creation flow without introducing a separate offline/online app branch
- [ ] Ensure board creation records `mode = offline`
- [ ] Ensure board creation always results in at least three stages
- [ ] Ensure exactly one terminal success stage exists
- [ ] Ensure exactly one terminal failure stage exists
- [ ] Implement offline board list projection
- [ ] Persist created offline boards locally

## Phase 8. Offline Board Stage Management

- [ ] Implement add stage to end
- [ ] Implement rename stage
- [ ] Implement delete non-terminal stage
- [ ] Reassign tasks from deleted stage to first available stage
- [ ] Prevent deletion of terminal stages
- [ ] Allow rename of terminal stages
- [ ] Persist stage order changes locally

## Phase 9. Offline Task Creation And Detail

- [ ] Implement create offline task flow
- [ ] Assign task to project
- [ ] Assign task to board when board context is active
- [ ] Assign task to stage when board workflow is active
- [ ] Implement offline `TaskPage`
- [ ] Show current stage in task detail
- [ ] Show compact stage progress line in task detail
- [ ] Persist offline tasks locally

## Phase 10. Offline Task List

- [ ] Implement offline `TaskList` page
- [ ] Show task title
- [ ] Show current stage in list mode
- [ ] Support opening `TaskPage` from list
- [ ] Ensure list reads from offline local typed projections only

## Phase 11. Offline Kanban

- [ ] Implement offline `KanbanBoard` page
- [ ] Group tasks by current stage
- [ ] Render stage columns in order
- [ ] Render task cards with compact stage-progress line
- [ ] Support opening `TaskPage` from kanban card
- [ ] Ensure kanban reads from offline local typed projections only

## Phase 12. Offline Drag And Drop

- [ ] Implement drag source for task cards
- [ ] Implement drop target for stage columns
- [ ] Update task stage through event flow, not direct view mutation
- [ ] Persist stage movement locally
- [ ] Re-render list, task detail, and kanban from updated local projections

## Phase 13. Offline Terminal Actions

- [ ] Add complete action on task card
- [ ] Add fail action on task card
- [ ] Add complete action on task page
- [ ] Add fail action on task page
- [ ] Move task into terminal success stage on complete
- [ ] Move task into terminal failure stage on fail
- [ ] Ensure terminal actions stay consistent across list, card, and detail projections

## Phase 14. Online Architecture Stub

This phase is about making the online path architecturally ready without pretending sync exists.

- [ ] Define online board API client boundary
- [ ] Define online board read models
- [ ] Define online board write models
- [ ] Define auth gate for online boards
- [ ] Define unavailable/offline state for online boards when network is missing
- [ ] Ensure no online feature falls back to local durable writes

## Phase 15. Cleanup Of Old Sync Direction

- [ ] Remove or rename files, types, comments, and tests that still describe sync/outbox/reconciliation architecture
- [ ] Remove outdated references to `lastModifiedAt` and latest-version replacement where they no longer apply
- [ ] Update Swift tests to match the board-mode contract and remove sync-era assertions
- [ ] Update README files that still describe offline-first sync
- [ ] Confirm backend/API docs describe online boards only

## Phase 16. Validation

- [ ] Run fast diagnostics for touched Swift files
- [ ] Build the macOS project when buildable
- [ ] Fix actionable compiler errors
- [ ] Fix actionable warnings that reflect real issues
- [ ] Document any validation limitation if full build cannot run

## Phase 17. Documentation Sync

- [ ] Update canonical docs if model meanings changed
- [ ] Update canonical docs if flow boundaries changed
- [ ] Update canonical docs if persistence conventions changed
- [ ] Update canonical docs if online API boundaries changed
- [ ] Mark completed tasks in this file

## Definition Of Done For First Executable Vertical Slice

The first executable slice is now offline-only.

- [ ] `Home` opens as placeholder-only landing hub
- [ ] User can create a project
- [ ] User can create an offline board
- [ ] User can create an offline board from preset copy
- [ ] Board preserves valid stage invariants
- [ ] User can create an offline task
- [ ] List shows current stage
- [ ] Kanban groups tasks by stage
- [ ] Drag-and-drop moves tasks between stage columns
- [ ] Complete moves a task to terminal success stage
- [ ] Fail moves a task to terminal failure stage
- [ ] Offline local state survives restart
- [ ] Relevant docs remain in sync with implementation
