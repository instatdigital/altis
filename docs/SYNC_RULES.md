# Offline-First Sync Rules

Status: Accepted

## Problem / Context

The project requires an offline-first architecture that behaves consistently under:

- loss of connectivity
- reconnect after local changes
- repeated command delivery
- multi-client access
- server confirmation arriving after local optimistic updates

The project contains at least two different sync classes of entities:

- ordinary CRUD entities such as tasks, projects, boards, filters, and settings
- ledger-like entities where history and invariants matter more than the latest scalar value

The architecture MUST support both classes without collapsing them into one unsafe synchronization model.

## Decision

The project adopts an offline-first architecture with one local read path and one local write path.

UI MUST read from local storage only.

All writes MUST first be recorded locally and MUST then be scheduled for synchronization through an outbox or equivalent durable pending-operation mechanism.

The project MUST distinguish between:

- state-based sync for ordinary CRUD entities
- operation-based sync for ledger-like or invariant-sensitive entities

For ordinary CRUD entities, the local store may hold the current entity state plus version metadata.

For ledger-like entities, the source of truth is the confirmed sequence of operations, not the last stored numeric value.

## Rules

### Core principles

- The system MUST be offline-first.
- The UI MUST read from the local store, not directly from network responses.
- The system MUST have a single logical write path for both offline and online conditions.
- The online case MUST reuse the same local-first write path rather than bypassing it.
- Local persistence MUST be durable enough to survive app restarts before sync completes.
- Sync MUST reconcile local state with server-confirmed state without introducing a separate online-only truth path.

### Read model

- User-facing screens and components MUST render from local typed read models.
- A read model MAY be a projection over canonical domain entities and confirmed plus pending operations.
- Network responses MUST update the local store first; only then MAY the UI reflect the change through local subscriptions.
- The local store is the runtime source of truth for rendering.
- For ledger-like entities, the UI read model MUST be treated as a projection, not the authoritative ledger.

### Write model

- Every user write MUST enter the local store first.
- Every user write MUST create or update an outbox item, pending operation record, or equivalent durable sync intent.
- The write path MUST be the same regardless of whether the network is currently available.
- The write model MUST assign stable client-side identifiers for operations where idempotency or replay matters.
- A network request MUST NOT be treated as the primary write.
- Server confirmation MUST be applied by updating the local store from the confirmed response or confirmed operation result.

### Sync model

- Sync MUST consume durable local intents rather than transient UI callbacks.
- Sync MUST support retry after network restoration.
- Sync MUST support idempotent re-delivery of operations.
- Sync MUST support reconciliation when multiple clients update the same logical entity.
- Sync MUST be able to reload authoritative server state or authoritative confirmed operations when local projections become stale.
- Reconnect MUST trigger reconciliation against the server source of truth and rebase remaining local pending work on top of the confirmed state.

### Conflict resolution

- Conflict handling MUST be explicit.
- Conflicts MUST NOT be silently overwritten when invariant-sensitive data is involved.
- Ordinary CRUD entities MAY use state-based conflict policies when the chosen policy is documented and safe for that entity class.
- Ledger-like entities MUST resolve conflicts through operation history, idempotency, rejection, compensation, or explicit user-visible error handling.
- When rebase fails, the system MUST preserve the pending intent and mark it as failed, rejected, or requiring intervention.

### Rules for balance / ledger-like entities

- Ledger-like entities MUST use operation-based sync.
- Ledger-like entities MUST NOT use last-write-wins as the authoritative merge rule.
- The local scalar value for a ledger-like entity MUST be treated as a projection.
- The authoritative model for a ledger-like entity MUST be the confirmed sequence of operations plus domain rules.
- The UI projected state MUST be computed as:

`projected state = confirmed state + pending local operations`

- The server MUST support idempotent operation submission.
- Reconnect MUST reconcile confirmed operations first, then rebase pending local operations on top of the confirmed base.
- Background sync MUST NOT silently "fix" balances by overwriting the projected value with an unexplained number.
- Any correction to a ledger-like entity MUST occur through explicit operations, compensations, reconciliation logic, or surfaced conflict states.

### Rules for ordinary CRUD entities

- Ordinary CRUD entities MAY use state-based sync with explicit version metadata.
- Ordinary CRUD entities SHOULD include version, revision, or `lastModifiedAt` metadata suitable for conflict detection.
- Server-confirmed state MAY replace local state when the entity class is documented as state-synchronized.
- Local pending writes for CRUD entities MUST still go through the local write path and outbox.
- State-based sync for CRUD entities MUST still preserve deterministic conflict handling and retry semantics.

## Invariants

- UI MUST read from local storage.
- UI MUST NOT read directly from the network as its source of truth.
- Every mutation MUST pass through the local write path.
- The system MUST NOT have separate offline and online write-path logic with different business semantics.
- Every synchronizable local write MUST produce durable sync intent before it is considered accepted.
- Server confirmation MUST update local state before the UI reflects the confirmed result.
- For CRUD entities, local state MAY be authoritative for rendering but server-confirmed state remains authoritative for sync reconciliation.
- For ledger-like entities, the source of truth MUST be confirmed operations, not the last stored scalar value.
- Reconnect MUST reconcile confirmed remote state before replaying or rebasing pending local operations.
- Conflict resolution MUST be explicit for any entity where overwrite could violate invariants.

## Examples

### Task entity

Entity class:

- ordinary CRUD

Flow:

1. The user edits a task title.
2. The app writes the new task state to the local store with updated local sync metadata.
3. The app creates or updates an outbox record for task synchronization.
4. The UI re-renders from the local task state.
5. Sync sends the task state with version metadata.
6. The server accepts and returns the confirmed task state.
7. The local store is updated from the server-confirmed state.
8. Any remaining pending metadata is cleared or advanced.

### Balance / account / reserve entity

Entity class:

- ledger-like

Flow:

1. The user submits a reserve operation.
2. The app records the pending operation locally with an idempotency key.
3. The app derives projected UI state as confirmed balance plus pending reserve operations.
4. The UI renders the projected state from the local projection.
5. Sync sends the operation, not a new absolute balance number.
6. The server accepts, rejects, or partially applies the operation according to domain rules.
7. The local store records the confirmed operation result.
8. The projected state is recalculated from confirmed operations plus any remaining pending operations.

## Anti-patterns

- MUST NOT use last updated scalar state as the source of truth for balances, reserves, limits, or similar invariant-sensitive entities.
- MUST NOT implement separate write paths for online and offline behavior.
- MUST NOT update UI directly from a network response in bypass of the local store.
- MUST NOT silently overwrite conflicting values for invariant-sensitive entities.
- MUST NOT repair balance drift by overwriting a number without explicit reconciliation semantics.
- MUST NOT model operation-based sync as only "a queue of HTTP requests" without operation identity, idempotency, confirmed history, and rebase semantics.
- MUST NOT treat pending projected balance as confirmed truth.
- MUST NOT let background sync mutate ledger-like projections in ways that are not explainable by confirmed or pending operations.

## Consequences

- The architecture becomes stricter but more predictable under unreliable connectivity.
- UI and domain layers become simpler to reason about because they depend on one local read model.
- Sync infrastructure becomes more explicit because it must support durable intent storage, retries, reconciliation, and idempotency.
- Ordinary CRUD entities remain relatively simple.
- Ledger-like entities require explicit operation modeling and cannot be treated as simple overwriteable records.
- The server contract must support confirmation semantics and idempotent operation handling where required.

## Implementation guidance

- Keep local read models typed and derived from stable domain models or stable projections.
- Separate domain entities, local persistence records, transport payloads, and sync metadata.
- Represent pending local writes explicitly rather than inferring them from transient UI state.
- Use version metadata for CRUD reconciliation.
- Use operation identifiers and server-supported idempotency for ledger-like entities.
- During reconnect, load confirmed remote base first, then replay or rebase still-pending local operations.
- Surface failed, rejected, or conflicting operations explicitly to the application state rather than hiding them in transport logs.
- Ensure event-driven UI flows subscribe to local projections and not directly to network callbacks.

## Glossary

- `Local store`: durable local persistence used by the app as the read source for UI.
- `Outbox`: durable queue or table of local sync intents pending confirmation.
- `Confirmed state`: state derived only from operations or entity versions acknowledged by the server.
- `Pending local operations`: locally accepted writes not yet confirmed by the server.
- `Projected state`: UI-facing derived state built from confirmed state plus pending local operations where applicable.
- `State-based sync`: synchronization of current entity state together with version metadata.
- `Operation-based sync`: synchronization of explicit domain operations, commands, or events instead of only final scalar state.
- `Rebase`: recomputation of pending local intent on top of a newly confirmed remote base.
