# Altis Windows

Windows application scope for Altis.

## Agent Context (Canonical Docs)

Before implementation work in `windows`, load:

- `../AGENTS.md`
- `../docs/ARCHITECTURE.md` (including `Global Artifact Classification Workflow`)
- `../docs/MVP_APP_STRUCTURE.md`
- `../docs/TYPES_AND_CONTRACTS.md`
- `../docs/SYNC_RULES.md`
- `../docs/DEVELOPMENT_RULES.md`
- `../docs/PROJECT_SETUP.md`

## Planned ownership

- Windows app shell
- Windows-specific resources and integrations
- Windows tests

## Placement reminder

- Keep platform-specific UI, wiring, and adapters inside `windows/`.
- Keep cross-platform contracts and rules in `shared/` according to the global classification workflow.
