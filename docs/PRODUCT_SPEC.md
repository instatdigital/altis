# Product Spec

## Product

Altis is a task manager for multiple platforms.

## Core experiences

- flat task list
- kanban board

Both experiences operate on the same underlying task model and should support grouping tasks by project and by board.

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

These sections should feel coherent as one task workflow, while remaining architecture-first at this stage.

## Primary differentiator

Widget-level task filters are the main feature. Users should be able to configure task visibility for widgets using reusable filter definitions that also make sense inside the main app.

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
- stage presets are workspace-level reusable definitions from which new boards can be assembled
- boards created from presets are created by copying the preset definition, not by keeping a live link to it

Stage management in MVP must support:

- add stage to the end
- rename stage
- delete stage

Stage constraints:

- terminal stages may be renamed
- terminal stages must not be deleted
- when a non-terminal stage is deleted, tasks from that stage move to the first available stage

## Presentation rules for stages

- in list mode, a task must show its current stage
- in task cards, the task should show a compact stage-progress line with the current stage
- in kanban mode, cards must be distributed by current stage
- task cards and task pages must expose explicit actions to move a task to the terminal successful or terminal unsuccessful stage

## Homepage

The product should include a homepage entry surface before the detailed project and board flows.

Initial homepage scope may use placeholders, but it must act as the canonical landing point for:

- dashboards
- project lists
- board entry points

Current MVP assumption:

- homepage sections may be placeholder surfaces
- homepage is placeholder-only in the first vertical slice
- homepage does not load live project, board, task, or dashboard data in the first vertical slice
- placeholder scope remains open only in terms of exact content density, ordering, and empty-state behavior

## Secondary capabilities

- offline-first local storage
- latest-version synchronization for tasks
- local task records with `lastModifiedAt`
- full replacement of a task with the current backend version during sync for ordinary CRUD entities

## Additional planned capabilities

- collaboration
- real-time updates when connected to the network
- native Apple ID authorization

## Deferred capabilities

- calendar sync
- Google authorization

## Product implications for architecture

- filters are a domain concept, not just a UI concern
- widgets and full apps should read from compatible filter definitions
- project and board are canonical product entities, not optional UI groupings
- board stages are canonical workflow entities inside board context, not kanban-only decoration
- terminal successful and unsuccessful stages must be explicit in the board model
- stage presets must be reusable definitions rather than per-screen ad hoc templates
- permissions for stage and preset editing are deferred from MVP
