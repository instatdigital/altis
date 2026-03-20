# CI/CD

## Scope

CI/CD is defined through GitHub Actions in `.github/workflows/` and reusable helpers in `tooling/ci/`.

## Initial direction

- keep workflows separated by platform or shared concern
- centralize repeated steps in reusable workflow files or scripts
- avoid embedding large shell logic directly in workflow YAML when a script can own it
- make CI reflect the same build, lint, and validation expectations defined for local project work
- prefer per-project validation steps over one opaque global script when failures need clear ownership
