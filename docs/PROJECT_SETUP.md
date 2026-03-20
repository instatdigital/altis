# Project Setup Rules

## Purpose

This document defines setup rules at the level of an individual project, app, package, or module, not only at monorepo root.

Agents should use these rules whenever they create or evolve a concrete project inside the repository.

## Required project-level setup areas

Each real project should explicitly consider:

- environment files
- formatter and linter configuration
- local developer bootstrap instructions
- build and validation commands
- project-local ignore rules if needed

## Environment files

- If a project needs environment-based configuration, define it at project scope, not only at monorepo root.
- Commit a safe example file such as `.env.example`, `.env.template`, or platform-equivalent sample config.
- Never commit real secrets.
- Document required keys, expected formats, and which values are optional.
- Keep runtime secret loading behind project-level configuration boundaries.
- If a platform does not conventionally use `.env`, provide the equivalent sample configuration file and document it in that project.

Recommended placement examples:

- `apple/ios/<ProjectName>/.env.example`
- `apple/macos/<ProjectName>/.env.example`
- `android/<ProjectName>/.env.example`
- `windows/<ProjectName>/.env.example`
- `shared/<PackageName>/.env.example` when a shared service or tool truly needs it
- `apple/ios/Config/*.xcconfig` or `apple/macos/Config/*.xcconfig` for Apple build-time configuration

## Linters and formatters

- Every concrete project should declare its formatter or linter choice explicitly.
- Prefer established tooling for the stack instead of custom formatting scripts.
- Commit formatter and linter configs with the project so behavior is reproducible.
- Use one primary formatter per language where possible.
- Keep lint rules strict enough to catch real quality issues, but avoid noisy or purely cosmetic rules that create churn.

Recommended defaults by ecosystem:

- JavaScript or TypeScript: `prettier` for formatting and `eslint` for linting
- Swift: `swift-format` or `swiftlint` when the project actually benefits from it
- Kotlin: `ktlint` or the platform-standard formatter/linter
- General config files: rely on the dominant formatter for that project rather than ad hoc scripts
- NestJS backend: `prettier` plus `eslint` with TypeScript-aware rules

Recommended placement examples:

- `apple/ios/<ProjectName>/.swift-format`
- `apple/ios/<ProjectName>/.swiftlint.yml`
- `android/<ProjectName>/.editorconfig`
- `shared/<PackageName>/prettier.config.*`
- `shared/<PackageName>/eslint.config.*`

## Apple project bootstrap

For Apple app projects, initialize these files and folders as the default minimum unless the project has a stronger existing convention:

- `README.md`
- `.env.example`
- `.swift-format`
- optional `.swiftlint.yml` when linting is enabled for that project
- `Config/Base.xcconfig`
- `Config/Debug.xcconfig`
- `Config/Release.xcconfig`
- `App/`
- `Resources/`
- `Tests/`
- `UITests/`

For Apple-only shared code, prefer a local Swift package when that code can be validated independently of an app target.

## Build and validation contract

- Each project should have a documented local validation path.
- Agents should run the strongest relevant validation available after making changes.
- The preferred order is: build plus tests, then lints, then lightweight diagnostics when full build is unavailable.
- Errors must be fixed.
- Actionable warnings should also be fixed unless there is a documented reason not to.

Project-level validation should be discoverable through one of:

- documented commands in the project README
- scripts in the project directory
- project-local tooling config
- CI workflow definitions

For a NestJS backend project, the baseline validation path should usually include:

- install dependencies
- generate Prisma client when needed
- lint
- test
- build

## Bootstrap and installation files

- Each project should document how to install dependencies, prepare environment files, and run local validation.
- Prefer a project-level README when setup differs from repository root.
- If a project needs setup scripts, place them near that project or in `tooling/` with clear ownership.
- Avoid hidden setup steps that exist only in CI.

Useful project-level files may include:

- `README.md`
- `.env.example`
- `.editorconfig`
- formatter config
- linter config
- project-specific ignore files
- setup or bootstrap scripts

For a NestJS plus Prisma backend, the minimal project bootstrap usually includes:

- `package.json`
- `tsconfig.json`
- `nest-cli.json`
- `eslint.config.*` or equivalent ESLint config
- `prettier.config.*` or equivalent Prettier config
- `.env.example`
- `prisma/schema.prisma`
- a project README with run, lint, test, build, and migration commands

## Agent behavior

- When creating a new project, agents should check whether these setup files already exist.
- If required setup files are missing, agents should create the minimal correct set for that project.
- If an agent introduces a new tool such as a formatter, linter, or environment convention, it must also add the relevant config and documentation in the same change.
- Do not add project tooling only at monorepo root when the behavior is intended for a specific project.
- When bootstrapping an Apple project, agents should also define the local validation path or explicitly document why it is not available yet.
