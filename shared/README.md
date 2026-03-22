# Shared

Cross-platform shared logic and contracts live here.

## Canonical subareas

- `contracts/` transport-facing contracts
- `domain/` business concepts and rules
- `application/` use-case orchestration
- `persistence/` local storage abstractions and sync-facing persistence rules

## Rule

Do not mix transport contracts, persistence records, and UI state into one shared bucket.
