# Altis

Monorepo for the Altis product family.

Current goal: establish a stable repository structure and a product-aware architecture before platform-specific implementation starts.

## Product direction

Altis is a task manager with two primary presentation modes:

- flat task list
- kanban board

The main product differentiator is task filtering at the widget level. The architecture should optimize for fast, explicit, reusable filter definitions that can drive app screens and widgets from the same source of truth.

Secondary product focus:

- offline-first behavior
- sync of the latest task version
- local persistence with `lastModifiedAt`
- full replacement of the current task version during backend sync

Additional planned capabilities in the main architecture:

- collaboration
- real-time updates while network is available
- native Apple ID authorization

Deferred capabilities:

- calendar sync
- Google authorization

## Top-level layout

- `common/` shared assets, visual metaphors, and theme-dependent resources
- `shared/` cross-platform domain and application logic
- `backend/` backend services and server-side infrastructure
- `apple/shared/` Apple-only shared code for iOS and macOS
- `apple/ios/` iOS application targets and resources
- `apple/macos/` macOS application targets and resources
- `android/` Android application targets and resources
- `windows/` Windows application targets and resources
- `tooling/` scripts, CI helpers, templates, and automation
- `.github/workflows/` GitHub Actions workflows
- `docs/` architecture and delivery documentation

## Current stack direction

- Apple apps: Swift, SwiftUI, Xcode
- backend API: NestJS
- database access: Prisma
- contract boundary between client and backend: shared API contracts, not shared ORM models

## Agent context

The repository includes:

- `AGENTS.md` for Codex-style coding agents
- `CLAUDE.md` for Claude-style coding agents

These files define repository-wide expectations and should be treated as the default context for work inside `altis/`.
