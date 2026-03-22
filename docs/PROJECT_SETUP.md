# Project Setup

## Goal

Define project-level setup expectations that agents and developers must apply before implementation grows.

## Global rule

- Environment, formatting, linting, and project bootstrap rules MUST be applied per project, not only at monorepo root.

## Apple projects

Applies to:

- `apple/ios`
- `apple/macos`
- `apple/shared`

Rules:

- keep sample environment values in `.env.example`
- keep formatter configuration in `.swift-format`
- keep linter configuration in `.swiftlint.yml` where used
- keep Xcode build settings in `Config/*.xcconfig`
- keep app-local source under `App/`
- keep app-local resources under `Resources/`
- keep tests under `Tests/` and `UITests/`

## Backend project

Applies to:

- `backend/api-nest`

Rules:

- keep sample environment values in `.env.example`
- keep project-local lint and format config next to the backend project
- keep Prisma schema inside `prisma/`
- keep NestJS source inside `src/`

## Validation rule

- Any implementation task MUST run the strongest relevant validation available for the touched project.
- If full validation is not possible, document the limitation in the result.
