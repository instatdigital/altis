# Development Rules

- Keep the repository structure stable and predictable.
- Prefer small changes with clear ownership by layer.
- Avoid introducing platform-specific logic into `shared/`.
- Do not duplicate assets between platform directories unless required by build tooling.
- Record non-obvious structural decisions in `docs/DECISIONS.md`.
- Keep one canonical task model for list, kanban, and widget use cases.
- Treat widget filtering as a product-critical capability and reflect it in shared contracts.
- Prefer offline-first behavior in data flow decisions.
- Use `lastModifiedAt` or equivalent explicit version metadata for task synchronization.
- Default to full task replacement on sync unless a new ADR changes that rule.
- Keep deferred features out of active implementation paths until explicitly activated.
- Before adding a new file, check whether the intended target path exists.
- If a required directory is missing, create it in the correct layer before adding the file.
- Put shared assets and images in `common/assets/`.
- Put shared configs in `shared/config/`.
- Put shared reusable components in `shared/components/`.
- Put shared style definitions in `shared/styles/`.
- Put Apple-only shared components or wrappers in `apple/shared/`.
- Put scripts, CI helpers, and templates in `tooling/scripts/`, `tooling/ci/`, and `tooling/templates/`.
- If implementation introduces a new convention that is not already covered by the current rules, document that convention in the same change.
- Do not leave new placement, naming, or architectural patterns implicit.
- Prefer native platform UI components and interaction patterns over custom abstractions for end-user interface work.
- Introduce custom shared UI only when native controls do not cover the product need well enough.
- After making code or configuration changes, run the most relevant build, test, lint, or diagnostics step for the affected project.
- Fix errors and actionable warnings discovered during validation before considering the task complete.
- If validation cannot be executed, document what was attempted, what remains unverified, and why.
- Apply environment, `.env`, linter, formatter, and bootstrap rules from `docs/PROJECT_SETUP.md` at the project level.
- After UI changes, validate alignment with the relevant platform design guidelines and note any intentional deviations.
- When duplicate filesystem copies exist, changes MUST be applied to the real project working tree rather than only to an autosave or temporary mirror.

## Documentation source of truth

- `docs/MVP_APP_STRUCTURE.md` is the source of truth for product-level UX architecture.
- `docs/ARCHITECTURE.md` is the source of truth for repository, layer, module, component, and event-flow architecture.
- `docs/TYPES_AND_CONTRACTS.md` is the source of truth for canonical entities, relations, and typed model boundaries.
- `docs/SYNC_RULES.md` is the source of truth for offline-first synchronization architecture.
- `docs/WIDGET_RULES.md` is the source of truth for widget-specific constraints and widget-to-app handoff rules.
- Platform README files should only document platform-specific mappings or constraints, not replace the product-level UX contract.

## Data and flow rule

- Visual components MUST render typed incoming data and MUST emit typed user intents.
- Pages or containers MUST integrate visual components with the local or global event flows required for the feature.
- Feature flows MUST subscribe to relevant user, lifecycle, realtime, and sync events through one explicit event-driven pipeline.
- Initial data ingress and later online updates MUST enter the same feature flows and local projections.
- Feature flows MUST work with isolated data-facing classes or services rather than letting UI call persistence or transport directly.
- UI MUST read through local typed projections and MUST NOT treat network callbacks as the primary render source.
- All synchronization behavior MUST follow `docs/SYNC_RULES.md`.

## Component decision rule

- Before creating a new component, classify the need using the component taxonomy in `docs/ARCHITECTURE.md`.
- Before creating or moving a component, classify its placement level: `platform app`, `Apple shared`, or `global shared`.
- Search for an existing component of the same type and ownership boundary before creating a new one.
- If a suitable existing component exists, prefer reusing it.
- If a close existing component exists but does not fully satisfy the need, evaluate whether it can be extended without breaking its ownership or semantics.
- If an existing component can be safely extended, prefer extension over creating a new parallel component.
- If no suitable existing component can be reused or extended, create a new component in the narrowest correct ownership boundary and document the new pattern when it becomes part of the architecture.
- Do not promote a component from platform level to `apple/shared` or from `apple/shared` to `shared` without a real second consumer and a dependency check that proves the wider placement is valid.

## Documentation maintenance rule

- If implementation changes architecture, flow boundaries, section responsibilities, page responsibilities, state ownership, data contracts, entry points, cross-layer contracts, sync model, or component taxonomy, update the relevant documentation in the same change.
- If a change alters user flow at the product level, update `docs/MVP_APP_STRUCTURE.md`.
- If a change alters repository, layer, placement, event-flow, or component boundaries, update `docs/ARCHITECTURE.md`.
- If a change alters offline-first write-path, read-path, sync semantics, conflict handling, or reconciliation behavior, update `docs/SYNC_RULES.md`.
- If a change alters widget behavior or widget handoff, update `docs/WIDGET_RULES.md`.
- If an existing component is generalized, repurposed, or moved into a wider reuse boundary, update the relevant documentation to reflect the new scope.
- If a new reusable component type or placement convention is introduced, document it in the same change.
- Treat architecture, UX, or sync code changes without matching documentation updates as incomplete work.
