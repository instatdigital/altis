# Altis Agent Instructions

This file defines the default context for coding agents working in the `altis` monorepo.

## Repository purpose

Altis is a multi-platform application monorepo with explicit separation between:

- shared business logic
- Apple shared code
- platform app shells
- CI/CD and tooling
- common visual assets

## Product context

Altis is a task manager.

Primary user-facing modes:

- flat task list
- kanban board

Primary product feature:

- task filters at the widget level

Secondary product feature:

- offline-first local storage
- task-level `lastModifiedAt`
- sync based on replacing local task state with the latest backend version

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

## Domain guidance

- Model tasks and filters as core shared-domain concepts.
- Model projects and boards as core shared-domain concepts.
- Treat widget filters as first-class entities, not view-only state.
- Keep list and kanban as alternate presentations over the same task model.
- Treat project and board as canonical grouping entities, not as optional UI tags.
- Design sync around version replacement semantics, not field-by-field merge.
- Keep offline persistence and sync metadata in shared logic where possible.
- Treat collaboration and real-time delivery as extensions over the same canonical task state.
- Separate domain models from transport contracts and persistence models.
- Do not treat Prisma models as application-wide shared types.
- Prefer OpenAPI-first transport contracts for backend-client boundaries.

## UI guidance

- Prefer native platform components for user-facing interface work.
- Prefer platform-native navigation, menus, lists, forms, settings surfaces, and drag and drop behavior.
- Use custom shared UI only when it solves a real product requirement that native controls cannot cover well.
- After UI work, check the result against the relevant platform guidelines and fix obvious mismatches when possible.

## Working rules

- Prefer minimal, additive changes.
- Do not move assets out of `common/assets/` without an explicit migration decision.
- Preserve theme-aware asset naming conventions such as `*_light` and `*_dark`.
- Document architectural decisions in `docs/DECISIONS.md`.
- Update `docs/ARCHITECTURE.md` when directory ownership or module boundaries change.
- Track unresolved structural or product contracts in `docs/OPEN_QUESTIONS.md`.
- Treat this repository as a monorepo first, platform repo second.
- Do not introduce separate task models for list, kanban, and widgets without an explicit architectural decision.
- Do not implement deferred features as if they are active scope.
- Favor shared contracts for sync, filters, and live updates before platform-specific adapters.
- If a task introduces a new convention, placement rule, module boundary, artifact type, or workflow pattern not yet described in the docs, update the relevant rule files in the same change.
- Treat undocumented structural decisions as incomplete work until they are written down.
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
- transport contracts and API-facing schemas: `shared/contracts/`
- cross-platform domain entities and rules: `shared/domain/`
- cross-platform use-case orchestration: `shared/application/`
- persistence-facing shared contracts: `shared/persistence/`
- Apple-only shared configs or resources: `apple/shared/config/`
- shared domain components and reusable logic: `shared/`
- Apple shared UI or wrappers: `apple/shared/`
- platform-specific UI, resources, and app configuration: platform directory under `apple/ios/`, `apple/macos/`, `android/`, or `windows/`
- automation scripts and generation helpers: `tooling/scripts/`
- CI helpers and reusable pipeline support: `tooling/ci/`
- file templates and scaffolding assets: `tooling/templates/`
- architecture, product, and process documents: `docs/`

Project-level environment and tooling rules live in `docs/PROJECT_SETUP.md`. Agents must apply those rules per project or package, not only at monorepo root.

When a requested artifact has no directory yet, agents should create the narrowest valid path first, for example:

- `shared/config/`
- `shared/contracts/`
- `shared/domain/`
- `shared/application/`
- `shared/persistence/`
- `shared/components/`
- `shared/styles/`
- `apple/shared/components/`
- `apple/ios/resources/`

## Current phase

The repository is in bootstrap stage.

Expected work right now:

- define structure
- define conventions
- define product-aware architecture
- avoid premature implementation details
- keep placeholders lightweight and explicit
