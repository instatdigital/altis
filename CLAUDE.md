# Altis Claude Context

Use this repository structure as the default mental model.

## Product context

Altis is a task manager with:

- flat list mode
- kanban mode
- widget-level task filters as the main feature

Secondary architecture priority:

- offline-first persistence
- latest-version task sync
- `lastModifiedAt` tracking
- full task replacement on sync

Additional active direction:

- collaboration
- real-time updates on connected clients
- native Apple ID authorization

Deferred:

- calendar sync
- Google authorization

## Core layers

- `common/assets`: shared assets, styles, and theme metaphors
- `backend`: backend services and server-side infrastructure
- `shared`: cross-platform logic and contracts
- `apple/shared`: Apple shared layer
- `apple/ios`: iOS application layer
- `apple/macos`: macOS application layer
- `android`: Android application layer
- `windows`: Windows application layer
- `.github/workflows`: GitHub Actions CI/CD
- `tooling`: scripts, CI helpers, templates
- `docs`: architecture and product documentation

## Repository expectations

- Keep changes aligned with the declared layer boundaries.
- Prefer documenting decisions before introducing cross-layer coupling.
- Keep placeholders minimal until product and platform decisions are finalized.
- Respect theme-aware resources in `common/assets/`.
- Treat widget filters as core shared-domain data, not UI-only configuration.
- Keep list and kanban backed by the same canonical task model.
- Assume deferred features are out of scope unless the task explicitly activates them.
- If a change introduces a new repository convention or structure rule, document it in the same change instead of leaving it implicit.
- After implementation, run the most relevant build, diagnostics, or lint step available for the affected project and fix errors and meaningful warnings before considering the work done.
- Prefer shared transport contracts over shared language-specific runtime types across backend and clients.
- Prefer native platform components for user-facing UI and validate UI work against the relevant platform guidelines.

## Placement rules

- Check whether the expected target path already exists before creating new files.
- If a needed directory is missing, create the correct directory instead of placing the file in an adjacent path.
- Reuse existing shared locations before introducing new root-level folders.

Default placement:

- assets, icons, images, shared theme resources: `common/assets/`
- backend services and modules: `backend/`
- transport contracts and API schemas: `shared/contracts/`
- cross-platform domain types and rules: `shared/domain/`
- shared use-case orchestration: `shared/application/`
- shared persistence contracts: `shared/persistence/`
- cross-platform configs: `shared/config/`
- cross-platform shared components or primitives: `shared/components/`
- cross-platform styles or design constants outside raw assets: `shared/styles/`
- Apple shared components or wrappers: `apple/shared/`
- platform-specific UI, resources, and configs: platform folders
- scripts: `tooling/scripts/`
- CI helpers: `tooling/ci/`
- templates: `tooling/templates/`
- documentation: `docs/`

Project-specific environment, `.env`, linter, and setup rules are defined in `docs/PROJECT_SETUP.md` and should be applied at project scope.

## First reference files

Read these first when making non-trivial changes:

1. `README.md`
2. `docs/ARCHITECTURE.md`
3. `docs/DEVELOPMENT_RULES.md`
4. `docs/PRODUCT_SPEC.md`
5. `docs/PROJECT_SETUP.md`
6. `docs/DECISIONS.md`
7. `docs/OPEN_QUESTIONS.md`
