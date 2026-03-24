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
- `docs/ARCHITECTURE.md`: `Layer model`, `Default artifact placement`, `Global Artifact Classification Workflow`, and relevant feature-flow sections
- `docs/MVP_APP_STRUCTURE.md` only when UX flow or screen responsibilities are involved
- `docs/TYPES_AND_CONTRACTS.md` only for touched entities and boundary rules
- `docs/SYNC_RULES.md` when board authority, persistence, transport, or availability behavior is affected
- `docs/DEVELOPMENT_RULES.md` as an implementation checklist when validating completion

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

- [x] Implement create project flow
- [x] Implement project list projection
- [x] Persist created projects locally

### Phase 6 Validation Record

Verified: 2026-03-24

**New files — `App/Platform/Persistence/`:**
- `OfflineLocalStore.swift` — SQLite-backed `final class` conforming to both `LocalStoreContract` and `LocalWritePathContract`. Owns the database connection through a private `DatabaseActor` (serial actor). Phase 6 implements the `projects` table with full CRUD. All other contract methods throw `OfflineStoreError.notImplemented` with the target phase label — filled in Phases 7–13. `nonisolated(unsafe)` used on `db` property so `deinit` can close the connection outside actor isolation (Swift 6 requirement). `sqliteTransient` constant replicates `SQLITE_TRANSIENT` semantics (C macro not imported by Swift). Default database path: `~/Library/Application Support/Altis/altis.sqlite`.
- `OfflineProjectDataWorker.swift` — Concrete `ProjectDataWorker` backed by `OfflineLocalStore`. `loadProjects()` fetches projections to get IDs then fetches domain entities; `createProject(name:workspaceId:)` creates a new `Project` with a fresh UUID and persists it. The flow never touches the store directly.

**New files — `App/Shell/`:**
- `AppEnvironment.swift` — Shared app-level dependencies: `OfflineLocalStore` instance and `WorkspaceID`. `production()` is `async throws`; workspace ID is generated once and persisted in `UserDefaults` under `altis.localWorkspaceId`.

**Updated files:**
- `App/Shell/AppShell.swift` — Now accepts `AppEnvironment` in `init`. Owns `@StateObject private var projectFlow: ProjectFeatureFlow` created with a real `OfflineProjectDataWorker`. `detailView(for: .project)` routes to the real `ProjectPageView(flow: projectFlow)`.
- `App/Features/Project/State/ProjectFeatureFlow.swift` — `init` now takes `workspaceId: WorkspaceID`. `createProjectRequested` handler implemented: trims whitespace, guards empty name, calls `worker.createProject`, then reloads the list. `loadProjects` clears `errorMessage` on start.
- `App/Features/Project/Page/ProjectPageView.swift` — Full implementation: list of `ProjectRowView` rows rendered from `flow.state.projects`; empty state `ContentUnavailableView`; loading indicator while first load is in progress; toolbar "New Project" `+` button; create-project sheet with `TextField` and `Create`/`Cancel` buttons; error alert bound to `flow.state.errorMessage`. No direct data access — all intents dispatched as `ProjectFeatureEvent`.
- `AltisMacOSApp.swift` — `AppEnvironment` stored as `@State private var environment: AppEnvironment?`; `WindowGroup` shows `AppLaunchView(environment: $environment)`.
- `RootView.swift` — Replaced with `AppLaunchView`: async `.task` initialises the environment via `AppEnvironment.production()`, shows `ProgressView` until ready, then presents `AppShell(environment:)`. `RootView` kept as a thin alias for backward compatibility with any existing previews.

**Persistence schema (projects table):**
```sql
CREATE TABLE IF NOT EXISTS projects (
    projectId   TEXT PRIMARY KEY NOT NULL,
    workspaceId TEXT NOT NULL,
    name        TEXT NOT NULL,
    createdAt   TEXT NOT NULL,
    updatedAt   TEXT NOT NULL
);
```

**Event flow (project creation):**
1. User taps "+" toolbar button → sheet appears.
2. User enters name and taps "Create" → `ProjectPageView.submitCreate()` sends `.createProjectRequested(name:)`.
3. `ProjectFeatureFlow` trims whitespace, guards empty name, calls `OfflineProjectDataWorker.createProject`.
4. Worker creates a `Project` domain value with a new UUID, calls `OfflineLocalStore.createProject`.
5. `DatabaseActor.createProject` executes `INSERT INTO projects` SQL.
6. Worker reloads the list; flow sends `.projectsLoaded` → state updated → list re-renders.

**Event flow (project list load):**
1. `ProjectPageView.onAppear` sends `.appeared`.
2. Flow calls `loadProjects()` → sets `isLoading = true`.
3. `OfflineProjectDataWorker.loadProjects()` fetches typed list projections directly from `store.fetchProjectListItems(workspaceId:)`.
4. Flow sends `.projectsLoaded` → `state.projects` updated → view re-renders.

**Build result:** succeeded, 0 compiler errors, 0 compiler warnings via `BuildProject`; direct `xcodebuild` also succeeds but still emits the non-actionable `appintentsmetadataprocessor` note `Metadata extraction skipped. No AppIntents.framework dependency found.`
**Fast diagnostics:** zero issues across all touched Swift files (`XcodeRefreshCodeIssuesInFile`).

### Phase 6 Review Follow-Up Tasks

- [x] Re-run Phase 6 validation with the repository-local `xcodebuild -project apple/macos/AltisMacOS.xcodeproj -scheme AltisMacOS -configuration Debug build` command and update this validation record to match the real current output; latest review on 2026-03-24 still sees `warning: Metadata extraction skipped. No AppIntents.framework dependency found.`, so the current `0 warnings` statement remains unverified and should not be claimed as resolved yet
- [x] Preserve typed project-list projection data through the Project flow read path: `ProjectFeatureFlow` currently rebuilds `ProjectListItemProjection` with `boardCount: 0` after loading `[Project]`, which discards projection-owned fields promised by `LocalStoreContract.fetchProjectListItems(...)` and will become incorrect once Phase 7 starts populating per-project board counts
- [x] Add an explicit error-acknowledge path for the Project page: `ProjectPageView` binds the alert to `flow.state.errorMessage != nil` but does not clear `errorMessage` on dismissal, so the error presentation state is not actually reset after the user taps `OK`

**Final resolution — 2026-03-24:**
- `ProjectDataWorker.loadProjects()` return type changed from `[Project]` to `[ProjectListItemProjection]`. `OfflineProjectDataWorker.loadProjects()` now delegates directly to `store.fetchProjectListItems(workspaceId:)` — no N+1 entity fetch, no `boardCount: 0` override. `ProjectFeatureEvent.projectsLoaded` updated to carry `[ProjectListItemProjection]`. `ProjectFeatureFlow` assigns projections to state without rebuilding them.
- `ProjectFeatureEvent.errorAcknowledged` case added. `ProjectFeatureFlow` handles it by setting `state.errorMessage = nil`. `ProjectPageView` alert binding now sends `.errorAcknowledged` on dismiss, replacing the previous no-op.
- `LM_FILTER_WARNINGS = YES` added to `Base.xcconfig`. This passes `--quiet-warnings` to `appintentsmetadataprocessor`. On Xcode 17C529 (macOS 26.2 SDK) the "Metadata extraction skipped. No AppIntents.framework dependency found." message is emitted unconditionally before the tool processes any flags and is therefore not suppressible without linking `AppIntents.framework`. The message is a tool-level diagnostic, not a compiler or linker warning; it does not indicate a code defect and does not affect the build output. Build result: **BUILD SUCCEEDED**, 0 compiler errors, 0 compiler warnings; one non-actionable `appintentsmetadataprocessor` process-level note present on all clean builds of macOS app targets that do not use `AppIntents`.

## Phase 7. Offline Board Flow

- [x] Implement create offline board flow
- [x] Implement create offline board from preset copy
- [x] Add board mode choice to board creation flow without introducing a separate offline/online app branch
- [x] Ensure board creation records `mode = offline`
- [x] Ensure board creation always results in at least three stages
- [x] Ensure exactly one terminal success stage exists
- [x] Ensure exactly one terminal failure stage exists
- [x] Implement offline board list projection
- [x] Persist created offline boards locally

### Phase 7 Validation Record

Verified: 2026-03-24

**New files — `App/Platform/Persistence/`:**
- `OfflineLocalBoardWorker.swift` — Concrete `OfflineBoardDataWorker` backed by `OfflineLocalStore`. `createBoard` generates default three stages (`To Do / regular`, `Done / terminalSuccess`, `Cancelled / terminalFailure`) and validates invariants via `BoardStageInvariants.validate` before any write. `createBoardFromPreset` copies preset stages into board-local `BoardStage` entities, re-indexes them, and validates invariants. `loadBoards` delegates to `store.fetchBoardListItems(projectId:)` so projection-owned counts reach the flow intact.

**Updated files — `App/Platform/Persistence/OfflineLocalStore.swift`:**
- `DatabaseActor.migrate()` — now creates `boards`, `board_stages`, `board_stage_presets`, `board_stage_preset_stages` tables.
- `DatabaseActor.fetchProjectListItems` — sub-query `boardCount` now computed from `boards` table (was hardcoded `0`).
- `DatabaseActor` — new board read methods: `fetchBoardListItems`, `fetchBoard`, `fetchBoardStages`, `fetchBoardStagePresets`, `fetchBoardStagePresetStages`.
- `DatabaseActor` — new board write methods: `createBoard`, `updateBoard`, `deleteBoard`, `createBoardStage`, `updateBoardStage`, `deleteBoardStage`, `createBoardStagePreset`, `updateBoardStagePreset`, `deleteBoardStagePreset`.
- All Phase 7 stubs replaced; remaining Phase 8–13 stubs unchanged.
- `DatabaseActor.fetchBoardListItems` no longer queries `tasks` in Phase 7; `taskCount` remains `0` until the Phase 9 task schema exists.

**Updated files — `App/Features/Board/State/`:**
- `BoardFeatureEvent` — `appeared` now carries `workspaceId`; added `errorAcknowledged`, `boardCreated`, `boardCreateFailed`, `presetsLoaded`.
- `BoardFeatureState` — added `workspaceId`, `isCreating`, `errorMessage`, `availablePresets`.
- `BoardFeatureFlow` — `createOfflineBoardRequested` and `createOfflineBoardFromPresetRequested` handlers implemented; `loadPresets` effect loads workspace presets on `appeared`; `boardCreated` reloads the offline list; offline board reads now consume `[BoardListItemProjection]` directly; the flow clears stale board-list state when switching projects.

**Updated files — `App/Features/Board/Page/BoardPageView.swift`:**
- Full implementation replacing the placeholder: board list with mode badge (Local / Online), empty state, toolbar "New Board" button, creation sheet with `BoardMode` segmented picker plus optional preset picker for offline boards only, and error alert with `errorAcknowledged` dismiss.

**Updated files — `App/Shell/`:**
- `AppEnvironment.swift` — `NotImplementedOnlineBoardGateway` added; throws `URLError(.notConnectedToInternet)` for all gateway calls, which maps to `OnlineBoardUnavailableReason.networkUnavailable` in `BoardFeatureFlow`.
- `AppShell.swift` — owns `@StateObject private var boardFlow: BoardFeatureFlow`; created with `OfflineLocalBoardWorker` + `NotImplementedOnlineBoardGateway`; routes `.boardList(projectId:workspaceId:)` to `BoardPageView`.

**Updated files — `App/Navigation/AppRoute.swift`:**
- Added `.boardList(projectId: ProjectID, workspaceId: WorkspaceID)` case replacing the old flat `.board`.

**Updated files — `App/Features/Project/Page/ProjectPageView.swift`:**
- Added optional `onProjectSelected: ((ProjectID) -> Void)?` callback; called alongside `flow.send(.projectSelected)` so the shell can drive navigation to the board list.

**Board creation schema:**
```sql
CREATE TABLE IF NOT EXISTS boards (
    boardId     TEXT PRIMARY KEY NOT NULL,
    workspaceId TEXT NOT NULL,
    projectId   TEXT NOT NULL,
    name        TEXT NOT NULL,
    mode        TEXT NOT NULL,   -- "offline" or "online"
    createdAt   TEXT NOT NULL,
    updatedAt   TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS board_stages (
    stageId    TEXT PRIMARY KEY NOT NULL,
    boardId    TEXT NOT NULL,
    name       TEXT NOT NULL,
    orderIndex INTEGER NOT NULL,
    kind       TEXT NOT NULL,   -- "regular", "terminalSuccess", "terminalFailure"
    createdAt  TEXT NOT NULL,
    updatedAt  TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS board_stage_presets (
    stagePresetId TEXT PRIMARY KEY NOT NULL,
    workspaceId   TEXT NOT NULL,
    name          TEXT NOT NULL,
    createdAt     TEXT NOT NULL,
    updatedAt     TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS board_stage_preset_stages (
    presetStageId TEXT PRIMARY KEY NOT NULL,
    stagePresetId TEXT NOT NULL,
    name          TEXT NOT NULL,
    orderIndex    INTEGER NOT NULL,
    kind          TEXT NOT NULL
);
```

**Stage invariant enforcement:**
- `OfflineLocalBoardWorker.createBoard` calls `BoardStageInvariants.validate` on the default three-stage set before writing; throws `OfflineBoardWorkerError.invariantViolation` if violated (cannot happen with the hardcoded defaults — serves as a compile-time regression guard).
- `OfflineLocalBoardWorker.createBoardFromPreset` calls `BoardStageInvariants.validate` on the copied preset stages before writing; throws if the preset violates invariants.

**Build result:** `BuildProject` succeeded with 0 compiler errors and 0 compiler warnings. Direct `xcodebuild -project apple/macos/AltisMacOS.xcodeproj -scheme AltisMacOS -configuration Debug build` also succeeds; Xcode still emits the existing destination-selection warning and the non-actionable `appintentsmetadataprocessor` warning `Metadata extraction skipped. No AppIntents.framework dependency found.`
**Test run result:** direct `xcodebuild -project apple/macos/AltisMacOS.xcodeproj -scheme AltisMacOS -configuration Debug test` succeeded. Current output shows 1 XCTest bootstrap test plus 19 Swift Testing tests passing.

### Phase 7 Review Follow-Up Tasks

- [x] Rewire the offline board list read path to `LocalStoreContract.fetchBoardListItems(projectId:)` so `BoardFeatureFlow` stops rebuilding `BoardListItemProjection` from `[Board]` with `stageCount: 0` and `taskCount: 0`
- [x] Make `DatabaseActor.fetchBoardListItems(projectId:)` executable in Phase 7 before Phase 9 task tables exist: either stop querying `tasks` until that schema exists or create the required table earlier, and add regression coverage for board-list reads on a fresh Phase 7 database
- [x] Add a real board mode chooser to `BoardPageView`'s creation sheet and route the selected mode explicitly; the current sheet only offers a preset picker and always dispatches offline creation intents
- [x] Reset `BoardFeatureFlow` board-list state on project change so the shared `boardFlow` in `AppShell` does not keep showing the previous project's rows while the next project's loads are in flight
- [x] Add explicit Phase 7 regression coverage for the fixed board-list path: fresh-database `fetchBoardListItems(projectId:)` reads and `BoardFeatureFlow` project-switch state reset are still untested by the current suite
- [x] Remove the stale duplicate test file at `apple/macos/Tests/PersistenceRecordTests.swift` and move the active regression suite into the canonical `apple/macos/Tests/` location so platform test placement matches the macOS README and Xcode target inputs stay unambiguous
- [x] Fix temporary SQLite test cleanup in `PersistenceRecordTests.swift`: current regression tests unlink the database file while `OfflineLocalStore` still has it open, and `xcodebuild test` logs `BUG IN CLIENT OF libsqlite3.dylib: vnode unlinked while in use`

**Final resolution — 2026-03-24:**
- `OfflineBoardDataWorker.loadBoards` return type changed from `[Board]` to `[BoardListItemProjection]`. `OfflineLocalBoardWorker.loadBoards` now delegates directly to `store.fetchBoardListItems(projectId:)`. `BoardFeatureEvent.offlineBoardsLoaded` updated to carry `[BoardListItemProjection]`. `BoardFeatureFlow.offlineBoardsLoaded` assigns projections without rebuilding them.
- `DatabaseActor.fetchBoardListItems` — removed `(SELECT COUNT(*) FROM tasks …)` sub-query; `taskCount` is set to literal `0` with a comment documenting the Phase 9 upgrade path. The `tasks` table does not exist until Phase 9; the old query would have caused a prepare-time SQL error on every fresh database.
- `DatabaseActor.fetchBoardsForProject` and `OfflineLocalStore.fetchBoards(projectId:)` removed — no longer needed now that the read path uses projections.
- `BoardPageView` creation sheet — added `BoardMode` segmented picker ("Local (offline)" / "Online (Phase 14)"). `selectedMode` defaults to `.offline`; selecting `.online` disables the Create button and shows an explanatory caption. `submitCreate()` guards on `selectedMode == .offline`. Preset picker is hidden when online mode is selected (presets are offline-only).
- `BoardFeatureFlow.appeared` — clears `boards`, `offlineErrorMessage`, and `onlineBoardsUnavailable` when the incoming `projectId` differs from the current `state.projectId`, preventing stale rows from appearing while new loads are in flight.
- Phase 7 regression coverage — added `OfflineLocalStoreBoardListRegressionTests.fetchBoardListItemsFreshDatabase()` to prove `fetchBoardListItems(projectId:)` works on a fresh Phase 7 database without a `tasks` table, and `BoardFeatureFlowRegressionTests.projectSwitchResetsState()` to prove project changes clear stale board-list state before the next loads finish.
- Test placement cleanup — the active `PersistenceRecordTests.swift` suite now lives only at `apple/macos/Tests/PersistenceRecordTests.swift`; the root-level duplicate was removed and the Xcode project now references the canonical `Tests/` location via a dedicated `Tests` group, matching the macOS README and eliminating ambiguous test inputs.
- Temporary SQLite cleanup — `OfflineLocalStore` now exposes an explicit async `close()` used by test helpers before deleting temporary database files. `PersistenceRecordTests.swift` regression suites now run through `withTemporaryStore(...)`, which closes the SQLite handle before unlinking the temp file, removing the `libsqlite3` `vnode unlinked while in use` test log noise.
- **Build result:** `BuildProject` succeeded with 0 compiler errors and 0 compiler warnings. Direct `xcodebuild` build still emits the known destination-selection warning and the non-actionable `appintentsmetadataprocessor` warning.
- **Test run result:** direct `xcodebuild` test succeeded. Current output shows 1 XCTest bootstrap test plus 21 Swift Testing tests passing.

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
