# Shared

Cross-platform shared logic and contracts live here.

## Canonical subareas

- `contracts/` transport-facing contracts
- `domain/` business concepts and rules
- `application/` use-case orchestration
- `persistence/` storage-facing contracts

## Rule

Do not mix backend ORM models, transport contracts, and client-local UI models into one shared bucket.
