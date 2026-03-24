# Altis Agent Instructions

This file defines the default context for coding agents working in the `altis` monorepo.

It is the primary source of truth for repository-wide agent rules.

## Repository purpose

Altis is a multi-platform application monorepo with explicit separation between:

- shared business logic
- Apple shared code
- platform app shells
- CI/CD and tooling
- common visual assets

## Working Copy Rule

- When the repository may exist both in a real project path and in an autosave or temporary copy, agents MUST treat the real Xcode project path as the source of truth for edits.
- Agents MUST verify the active project root before writing files when there is any sign of duplicate copies.
- Agents MUST NOT apply documentation or code changes only inside `Autosave Information` or another temporary mirror unless the user explicitly asks to work there.
- If content was prepared in an autosave copy, agents MUST sync the agreed files into the real project path before considering the work complete.
- After synchronization, agents SHOULD verify that the real project tree and the intended edited files match.

## Product context

Altis is a task manager.

Primary user-facing modes:

- flat task list
- kanban board

Primary product feature:

- task filters at the widget level

Secondary product feature:

- explicit board mode: `offline` or `online`
- offline boards stored only locally
- online boards available only through backend connectivity

Additional supported direction:

- collaboration
- real-time updates when the network is available
- native Apple ID authorization

Deferred, not for current architecture work unless explicitly requested:

- calendar sync
- Google authorization

## Architectural boundaries

- Keep backend code in `backend/`.
- Keep platform-independent logic in `shared/`.
- Keep Apple-specific shared code in `apple/shared/`.
- Keep iOS app code in `apple/ios/`.
- Keep macOS app code in `apple/macos/`.
- Keep Android app code in `android/`.
- Keep Windows app code in `windows/`.
- Keep reusable assets in `common/assets/`.
- Keep automation and templates in `tooling/`.

## Canonical docs

- `docs/MVP_APP_STRUCTURE.md` is the source of truth for product-level UX architecture.
- `docs/ARCHITECTURE.md` is the source of truth for repository, layer, module, component, and event-flow architecture.
- `docs/TYPES_AND_CONTRACTS.md` is the source of truth for canonical entities, relations, and typed model boundaries.
- `docs/SYNC_RULES.md` is the source of truth for offline-board vs online-board authority rules.
- `docs/WIDGET_RULES.md` is the source of truth for widget-specific UX and handoff constraints.
- Platform and layer README files should only add local specialization, not replace these product-level and repository-level contracts.

## Mandatory context bootstrap for platform scope work

- Before changing files inside any platform scope (`apple/ios`, `apple/macos`, `android`, `windows`, `backend`), agents MUST load:
  - `AGENTS.md`
  - `docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
  - `docs/TYPES_AND_CONTRACTS.md`
  - `docs/SYNC_RULES.md`
  - `docs/DEVELOPMENT_RULES.md`
  - nearest platform README
- Before creating or moving files, agents MUST run the global artifact classification workflow from `docs/ARCHITECTURE.md` and map the artifact to its canonical destination.
- If a platform README does not link to the canonical docs above, treat that as documentation debt and fix the README in the same change.

## Domain guidance

- Model tasks and filters as core shared-domain concepts.
- Model projects and boards as core shared-domain concepts.
- Treat widget filters as first-class entities, not view-only state.
- Keep list and kanban as alternate presentations over the same task model.
- Treat project and board as canonical grouping entities, not as optional UI tags.
- Treat board mode as a first-class domain rule.
- Follow `docs/SYNC_RULES.md` for all offline-board vs online-board authority and write-path behavior.
- Keep offline persistence in shared logic where possible.
- Do not introduce sync metadata, outbox behavior, or reconciliation logic unless a later decision explicitly restores that scope.
- Treat collaboration and real-time delivery as extensions over the same canonical task state.
- Separate domain models from transport contracts and persistence models.
- Do not treat Prisma models as application-wide shared types.
- Prefer OpenAPI-first transport contracts for backend-client boundaries.

## UI guidance

- Prefer native platform components for user-facing interface work.
- Prefer platform-native navigation, menus, lists, forms, settings surfaces, and drag and drop behavior.
- Use custom shared UI only when it solves a real product requirement that native controls cannot cover well.
- After UI work, check the result against the relevant platform guidelines and fix obvious mismatches when possible.
- Do not invent undocumented product-level flows, shells, or entry points. Update `docs/MVP_APP_STRUCTURE.md` first when those need to change.
- Treat pages as composition surfaces, visual components as typed renderers and intent emitters, and feature flows as event-driven orchestration analogous to BLoC.
- UI MUST render from typed projections or typed feature state rather than directly from network responses.

## Component workflow

- Before changing or adding a component, classify it using the taxonomy in `docs/ARCHITECTURE.md`.
- Before changing, adding, or moving a component, classify its placement level: `platform app`, `Apple shared`, or `global shared`.
- Search for an existing component with the same type, semantics, and ownership boundary before creating a new one.
- Prefer reuse first.
- If reuse is close but incomplete, evaluate extension of the existing component before creating a parallel component.
- Extend an existing component only if its responsibility, naming, and ownership remain coherent after the change.
- Create a new component only when reuse or extension would create semantic confusion, ownership leakage, or an unstable API.
- Do not promote a component to a wider level unless there is a real second consumer and the wider layer can host the component without platform leakage.
- If a component is widened into a new reuse scope, moved to a wider ownership boundary, or becomes a new documented reusable pattern, update the relevant documentation in the same change.

## Data and flow workflow

- Components MUST receive typed data suitable for rendering.
- Components MUST emit typed user intents rather than mutating data layers directly.
- Pages or containers MUST subscribe to the local or global flows required for their feature.
- Feature flows MUST process user, lifecycle, and online result events through one explicit event pipeline.
- Initial data load and later online updates MUST enter the same feature flows for the active board mode.
- Feature flows MUST use isolated data-facing classes or services for local persistence and transport access.
- UI-facing code MUST NOT call transport clients directly.
- Writes for offline boards MUST stay local-only.
- Writes for online boards MUST go through the online API path defined in `docs/SYNC_RULES.md`.

## Working rules

- Prefer minimal, additive changes.
- Do not move assets out of `common/assets/` without an explicit migration decision.
- Preserve theme-aware asset naming conventions such as `*_light` and `*_dark`.
- Document architectural decisions in `docs/DECISIONS.md`.
- Update `docs/ARCHITECTURE.md` when directory ownership, module boundaries, component taxonomy, event-flow rules, or component placement rules change.
- Update `docs/MVP_APP_STRUCTURE.md` when section responsibilities, entry points, context switching, task flow, account flow, or page responsibilities change.
- Update `docs/SYNC_RULES.md` when board-mode authority, local/offline write-path, online/API write-path, or mode transition rules change.
- Update `docs/WIDGET_RULES.md` when widget behavior, widget filters, or widget-to-app handoff change.
- Track unresolved structural or product contracts in `docs/OPEN_QUESTIONS.md`.
- Treat this repository as a monorepo first, platform repo second.
- Do not introduce separate task models for list, kanban, and widgets without an explicit architectural decision.
- Do not implement deferred features as if they are active scope.
- Favor shared contracts for online API boundaries, filters, and live updates before platform-specific adapters.
- If a task introduces a new convention, placement rule, module boundary, artifact type, workflow pattern, sync rule, or UX flow not yet described in the docs, update the relevant rule files in the same change.
- Treat undocumented structural decisions as incomplete work until they are written down.
- Treat undocumented UX architecture changes as incomplete work until they are written down.
- Treat undocumented sync architecture changes as incomplete work until they are written down.
- After implementation work, run the most relevant build or validation step available for the touched project and fix resulting errors and actionable warnings before considering the task complete.
- If full build verification is not possible, run the closest available validation, report the limitation, and leave the repository in the best verified state you can reach.

## Placement rules for agents

- Before creating a new file, check whether the expected directory already exists in the appropriate layer.
- If the target directory does not exist, create it in the correct layer before writing the file.
- Do not place files in a nearby convenient path if the expected path is missing.
- Prefer extending an existing shared location over inventing a new top-level folder.

Use these default destinations:

- shared visual assets, icons, images, and theme resources: `common/assets/`
- backend application modules and server infrastructure: `backend/`
- cross-platform configs and shared static definitions: `shared/config/`
- transport contracts and API-facing schemas: `shared/contracts/` (canonical specification and cross-platform reference; Apple Xcode targets cannot consume this directory directly because it is not a Swift Package — each Apple app target maintains a build-input mirror in `App/Models/Contracts/` that must stay structurally in sync with `shared/contracts/`; update both in the same change)
- cross-platform domain entities and rules: `shared/domain/`
- cross-platform use-case orchestration: `shared/application/`
- persistence-facing shared contracts and local store abstractions: `shared/persistence/`
- Apple-only shared configs or resources: `apple/shared/config/`
- shared domain components and reusable logic: `shared/`
- Apple shared UI or wrappers: `apple/shared/`
- platform-specific UI, resources, and app configuration: platform directory under `apple/ios/`, `apple/macos/`, `android/`, or `windows/`
- automation scripts and generation helpers: `tooling/scripts/`
- CI helpers and reusable pipeline support: `tooling/ci/`
- file templates and scaffolding assets: `tooling/templates/`
- architecture, product, and process documents: `docs/`

Project-level environment and tooling rules live in `docs/PROJECT_SETUP.md`. Agents must apply those rules per project or package, not only at monorepo root.

## Current phase

The repository is in bootstrap stage.

Expected work right now:

- define structure
- define conventions
- define product-aware architecture
- define UX architecture without overcommitting to visual design
- define strict offline-board vs online-board boundaries before implementation diverges
- start Apple implementation with a macOS-first vertical slice: create project -> create board from or without preset -> create task -> move by stage -> complete/fail -> persist locally
- avoid premature implementation details
- keep placeholders lightweight and explicit
