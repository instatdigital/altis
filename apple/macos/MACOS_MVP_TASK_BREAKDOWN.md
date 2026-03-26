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


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

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


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

## Phase 5. Offline Vertical Slice First

This remains the first executable macOS slice.

- [x] Implement placeholder-only `HomeShell`
- [x] Keep `Home` structurally unchanged while board mode remains a board property
- [x] Ensure `Home` does not load live online board data in the first slice


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

## Phase 6. Project Flow

- [x] Implement create project flow
- [x] Implement project list projection
- [x] Persist created projects locally


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

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


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

## Phase 8. Offline Board Stage Management

- [x] Implement add stage to end
- [x] Implement rename stage
- [x] Implement delete non-terminal stage
- [x] Reassign tasks from deleted stage to first available stage
- [x] Prevent deletion of terminal stages
- [x] Allow rename of terminal stages
- [x] Persist stage order changes locally


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

## Phase 9. Offline Task Creation And Detail

- [x] Implement create offline task flow
- [x] Assign task to project
- [x] Assign task to board when board context is active
- [x] Assign task to stage when board workflow is active
- [x] Implement offline `TaskPage`
- [x] Show current stage in task detail
- [x] Show compact stage progress line in task detail
- [x] Persist offline tasks locally


*(Historical validation and review records for this phase have been moved to [MACOS_MVP_VALIDATION_ARCHIVE.md](./MACOS_MVP_VALIDATION_ARCHIVE.md))*

## Phase 10. Offline Task List

- [x] Implement offline `TaskList` page
- [x] Show task title
- [x] Show current stage in list mode
- [x] Support opening `TaskPage` from list
- [x] Ensure list reads from offline local typed projections only

## Phase 11. Offline Kanban

- [x] Implement offline `KanbanBoard` page
- [x] Group tasks by current stage
- [x] Render stage columns in order
- [x] Render task cards with compact stage-progress line
- [x] Support opening `TaskPage` from kanban card
- [x] Ensure kanban reads from offline local typed projections only

## Phase 12. Offline Drag And Drop

- [x] Implement drag source for task cards
- [x] Implement drop target for stage columns
- [x] Update task stage through event flow, not direct view mutation
- [x] Persist stage movement locally
- [x] Re-render list, task detail, and kanban from updated local projections

## Phase 13. Offline Terminal Actions

- [x] Add complete action on task card
- [x] Add fail action on task card
- [x] Add complete action on task page
- [x] Add fail action on task page
- [x] Move task into terminal success stage on complete
- [x] Move task into terminal failure stage on fail
- [x] Ensure terminal actions stay consistent across list, card, and detail projections

## Phase 14. Online Architecture Stub

This phase is about making the online path architecturally ready without pretending sync exists.

- [x] Define online board API client boundary
- [x] Define online board read models
- [x] Define online board write models
- [x] Define auth gate for online boards
- [x] Define unavailable/offline state for online boards when network is missing
- [x] Ensure no online feature falls back to local durable writes

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
