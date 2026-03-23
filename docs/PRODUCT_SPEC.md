# Product Spec

## Product

Altis is a task manager for multiple platforms.

## Core experiences

- flat task list
- kanban board

Both experiences operate on the same underlying task model and support grouping tasks by project and by board.

## MVP sections

The first canonical app sections are:

- task list
- task page
- project context
- board context
- list or kanban mode switch
- kanban drag and drop
- board stage management
- stage preset selection for new boards
- profile
- settings
- theme switching
- authorization for online features

## Primary differentiator

Widget-level task filters are the main feature. Users should be able to configure task visibility for widgets using reusable filter definitions that also make sense inside the main app.

## Board mode model

Boards are created in one of two modes:

- `offline`
- `online`

Product rules:

- offline boards exist only locally
- online boards exist only through backend connectivity
- the product does not synchronize an offline board into an online board
- the mode is chosen explicitly and is not inferred from connectivity
- the mode is a board property, not a separate app mode

## Board stage model

Boards may define explicit task stages.

Product rules:

- a board may contain an ordered sequence of stages
- tasks move through board stages over time
- every board must have one terminal successful stage
- every board must have one terminal unsuccessful stage
- every staged board must have at least three stages: one ordinary stage, one terminal successful stage, and one terminal unsuccessful stage
- completing a task moves it into the terminal successful stage
- closing a task unsuccessfully moves it into the terminal unsuccessful stage
- boards may be created from stage presets
- boards created from presets are created by copying the preset definition, not by keeping a live link to it

## Homepage

The product should include a homepage entry surface before the detailed project and board flows.

Initial homepage scope may use placeholders, but it must act as the canonical landing point for:

- dashboards
- project and board entry points

## Additional planned capabilities

- collaboration for online boards
- real-time updates when connected to the network for online boards
- native Apple ID authorization

## Deferred capabilities

- offline-online sync
- calendar sync
- Google authorization

## Product implications for architecture

- filters are a domain concept, not just a UI concern
- widgets and full apps should read from compatible filter definitions
- project and board are canonical product entities, not optional UI groupings
- board stages are canonical workflow entities inside board context, not kanban-only decoration
- board mode is a canonical product concept because it changes authority, availability, and allowed flows
- board mode changes board behavior without requiring a separate top-level interface branch
- projects remain client-owned grouping entities in the current phase
- `projectId` remains a client-owned grouping reference even when a board is online
- workspace-scoped filters and stage presets remain shared support entities in the current phase
