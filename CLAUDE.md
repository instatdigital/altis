# Altis Claude Context

This file is a lightweight Claude entry point. Repository-wide rules live in `AGENTS.md` and the canonical docs under `docs/`.

## Default reading order

1. `AGENTS.md`
2. the nearest platform or layer README
3. only the canon required by the task, following `AGENTS.md#Lean context bootstrap`

Load extra files only by concern:

- repo layout: `README.md`
- backend scope: `docs/BACKEND_ARCHITECTURE.md`
- macOS phase tracking: `apple/macos/MACOS_MVP_TASK_BREAKDOWN.md`
- implementation checklist: `docs/DEVELOPMENT_RULES.md`

## Scope rule

- Do not duplicate monorepo-wide rules here or in platform files.
- Keep global rules in `AGENTS.md` and `docs/`.
- Keep platform-specific rules next to the platform they govern.
- Prefer the real project path over autosave or mirror copies when both exist.
