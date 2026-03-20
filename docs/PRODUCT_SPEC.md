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
- profile
- settings
- theme switching
- authorization for online features

These sections should feel coherent as one task workflow, similar in information density and navigation clarity to Todoist-style task management, while remaining architecture-first at this stage.

## Primary differentiator

Widget-level task filters are the main feature. Users should be able to configure task visibility for widgets using reusable filter definitions that also make sense inside the main app.

## Secondary capabilities

- offline-first local storage
- latest-version synchronization for tasks
- local task records with `lastModifiedAt`
- full replacement of a task with the current backend version during sync

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
- sync should keep implementation simple and deterministic in the first iteration
- platform-specific auth integrations should sit behind shared contracts
- project and board are canonical product entities, not optional UI groupings
