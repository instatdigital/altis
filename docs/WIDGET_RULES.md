# Widget Rules

## Scope

This file documents widget-specific UX and architectural constraints. It does not define a separate product mode.

The canonical app-level UX architecture lives in `docs/MVP_APP_STRUCTURE.md`.

## Core rule

- Widgets are alternate entry points into the same task, filter, project, and board architecture used by the main app.
- Widgets must not introduce a second task model, a second filter model, or a widget-only navigation mode that is undocumented in the app UX architecture.

## Filter contract

- Widget filters must reuse the same domain meaning as app filters.
- Filter serialization must remain stable enough for persistence, sync, and app handoff.
- If a widget requires a new filter capability, update shared contracts first and then document the user-facing flow here.

## Widget-to-app handoff

- Opening the app from a widget should resolve to an existing documented flow such as task detail, task list with filter context, project context, or board context.
- If a new handoff flow is required, update `docs/MVP_APP_STRUCTURE.md` in the same change.

## Documentation maintenance rule

- If implementation changes widget entry behavior, widget filter behavior, or widget-to-app handoff, update this file in the same change.
- If implementation changes the product-level UX flow behind widget entry, update both this file and `docs/MVP_APP_STRUCTURE.md`.
