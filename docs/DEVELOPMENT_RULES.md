# Development Rules

- Keep the repository structure stable and predictable.
- Prefer small changes with clear ownership by layer.
- Avoid introducing platform-specific logic into `shared/`.
- Keep one canonical task model for list, kanban, and widget use cases.
- Treat widget filtering as a product-critical capability and reflect it in shared contracts.
- Treat board mode as a first-class rule: `offline` boards are local-only, `online` boards are backend-only.
- Do not reintroduce sync metadata, outbox behavior, or reconciliation logic unless a new ADR explicitly does that.
- Keep deferred features out of active implementation paths until explicitly activated.
- Before adding a new file, check whether the intended target path exists.
- If a required directory is missing, create it in the correct layer before adding the file.
- Put shared assets and images in `common/assets/`.
- Put shared configs in `shared/config/`.
- Put shared reusable components in `shared/components/`.
- Put shared style definitions in `shared/styles/`.
- Put Apple-only shared components or wrappers in `apple/shared/`.
- Put scripts, CI helpers, and templates in `tooling/scripts/`, `tooling/ci/`, and `tooling/templates/`.
- After making code or configuration changes, run the most relevant build, test, lint, or diagnostics step for the affected project.
- Fix errors and actionable warnings discovered during validation before considering the task complete.

## Documentation source of truth

- `docs/MVP_APP_STRUCTURE.md` is the source of truth for product-level UX architecture.
- `docs/ARCHITECTURE.md` is the source of truth for repository, layer, module, component, and event-flow architecture.
- `docs/TYPES_AND_CONTRACTS.md` is the source of truth for canonical entities, relations, and typed model boundaries.
- `docs/SYNC_RULES.md` is the source of truth for offline-board vs online-board authority rules.
- `docs/WIDGET_RULES.md` is the source of truth for widget-specific constraints and widget-to-app handoff rules.

## Mandatory classification preflight

- For any platform-scoped task, read canonical docs first, then the nearest platform README.
- Before creating or moving files, run `Global Artifact Classification Workflow` in `docs/ARCHITECTURE.md`.
- If the nearest platform README does not link back to canonical docs and classification workflow, update that README in the same change before implementation proceeds.

## Data and flow rule

- Visual components MUST render typed incoming data and MUST emit typed user intents.
- Pages or containers MUST integrate visual components with the local or global event flows required for the feature.
- Feature flows MUST subscribe to relevant user, lifecycle, and online result events through one explicit event-driven pipeline.
- Feature flows MUST work with isolated data-facing classes or services rather than letting UI call persistence or transport directly.
- Offline boards MUST render through local typed projections.
- Online boards MUST render through typed feature state or explicit online read models.
- All board-mode behavior MUST follow `docs/SYNC_RULES.md`.

## Component decision rule

- Before creating a new component, classify the need using the component taxonomy in `docs/ARCHITECTURE.md`.
- Before creating or moving a component, classify its placement level: `platform app`, `Apple shared`, or `global shared`.
- Search for an existing component of the same type and ownership boundary before creating a new one.
- If a suitable existing component exists, prefer reusing it.
- If a close existing component exists but does not fully satisfy the need, evaluate whether it can be extended without breaking its ownership or semantics.
- If no suitable existing component can be reused or extended, create a new component in the narrowest correct ownership boundary and document the new pattern when it becomes part of the architecture.

## Documentation maintenance rule

- If implementation changes architecture, flow boundaries, section responsibilities, page responsibilities, state ownership, data contracts, entry points, cross-layer contracts, board mode, or component taxonomy, update the relevant documentation in the same change.
- If a change alters user flow at the product level, update `docs/MVP_APP_STRUCTURE.md`.
- If a change alters repository, layer, placement, event-flow, or component boundaries, update `docs/ARCHITECTURE.md`.
- If a change alters offline/online authority rules, local persistence scope, online API scope, or mode transition rules, update `docs/SYNC_RULES.md`.
- Treat architecture, UX, or board-mode code changes without matching documentation updates as incomplete work.
