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

- [ ] Define feature flow contract for `Home` in the offline-first executable slice
- [ ] Define feature flow contract for `Project`
- [ ] Define feature flow contract for offline `Board`
- [ ] Define feature flow contract for offline `TaskList`
- [ ] Define feature flow contract for offline `KanbanBoard`
- [ ] Define feature flow contract for offline `TaskPage`
- [ ] Define separate online feature flow contracts or routing points where online mode will later attach
- [ ] Define isolated data worker interfaces for offline local persistence
- [ ] Define isolated data worker interfaces for online transport
- [ ] Ensure board mode routes board-specific features into the correct data authority without creating a separate top-level shell

## Phase 5. Offline Vertical Slice First

This remains the first executable macOS slice.

- [ ] Implement placeholder-only `HomeShell`
- [ ] Keep `Home` structurally unchanged while board mode remains a board property
- [ ] Ensure `Home` does not load live online board data in the first slice

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
