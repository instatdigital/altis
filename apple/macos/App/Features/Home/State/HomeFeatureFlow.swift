import Foundation

/// Feature flow for the Home landing surface.
///
/// Owns the `HomeFeatureState` and processes `HomeFeatureEvent` values emitted
/// by `HomePageView`. In the first vertical slice Home is placeholder-only, so
/// this flow performs no data access. Data workers are introduced in Phase 5.
///
/// Architecture rules (from `docs/ARCHITECTURE.md`):
/// - Pages subscribe to this flow and dispatch events; they never mutate state directly.
/// - Feature flows MUST process events through one explicit pipeline.
@MainActor
final class HomeFeatureFlow: ObservableObject {

    @Published private(set) var state = HomeFeatureState()

    // MARK: - Event entry point

    func send(_ event: HomeFeatureEvent) {
        switch event {
        case .appeared:
            break // No-op until Phase 5 adds real dashboard loading.
        }
    }
}
