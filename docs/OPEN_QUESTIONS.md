# Open Questions

## Apple bootstrap gaps

The Apple layer is initialized, but these contracts are still unresolved:

- how Xcode projects or workspace will be generated and maintained
- minimum supported Apple OS versions as a product policy, not only bootstrap defaults
- whether widgets live in separate targets per platform or share more infrastructure in `apple/shared`
- signing, bundle identifier, and provisioning strategy
- how local `.env` values map to xcconfig, build settings, or runtime injection
- whether `swiftlint` is mandatory for Apple projects or optional per target
- how preview data, fixtures, and snapshot baselines should be stored
- what the canonical project naming convention is for Apple app targets and schemes

## Shared architecture gaps

- exact shared package boundaries under `shared/`
- contract for local persistence format and migration strategy
- contract for sync transport and retry behavior
- contract for collaboration presence and event delivery
- contract for widget filter serialization format
- exact required fields for `Project` and `Board` in the shared contract layer

## Backend and contract gaps

- how Swift client models will be generated from or mapped to backend contracts
- database choice and initial Prisma schema boundaries
- exact auth provider flow between Apple ID on clients and NestJS session or token handling
- how real-time events are versioned and reconciled with offline snapshots
- whether board membership is always project-scoped or can exist in a wider workspace scope later
