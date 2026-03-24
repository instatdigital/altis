# Development Rules

Use this file as an implementation checklist, not as a second architecture spec.

## Before editing

- Read `AGENTS.md`.
- Load only the canonical docs needed for the task.
- For platform work, read the nearest platform README and run `Global Artifact Classification Workflow` from `docs/ARCHITECTURE.md` before creating or moving files.

## During implementation

- Prefer small, additive changes with clear ownership.
- Keep one canonical task model across list, kanban, task detail, and widgets.
- Respect `Board.mode`: offline is local-only, online is backend-only.
- Do not add sync metadata, outbox logic, or hidden authority fallbacks.
- Keep UI on typed projections or feature state, not raw transport payloads.
- Keep persistence and transport behind typed services or workers.
- Reuse an existing component before creating a new one.
- Create a new component only in the narrowest correct ownership boundary.

## Documentation sync

- Update `docs/ARCHITECTURE.md` when layer, placement, event-flow, or component-boundary rules change.
- Update `docs/TYPES_AND_CONTRACTS.md` when entities, relations, or typed boundaries change.
- Update `docs/SYNC_RULES.md` when authority or write-path behavior changes.
- Update `docs/MVP_APP_STRUCTURE.md` when screens, navigation, or UX responsibilities change.
- Update README files when local ownership or setup instructions change.

## Validation

- Run the most relevant build, test, lint, or diagnostics step for the touched scope.
- Fix errors and actionable warnings before closing the task.
- If full verification is not possible, record the limitation clearly.

## Review gate

- Do not consider a task complete only because files or stubs exist.
- Verify that implemented semantics still match the canonical docs.
- If a feature claims to support multiple modes or authorities, review each claimed path, including unavailable states when relevant.
