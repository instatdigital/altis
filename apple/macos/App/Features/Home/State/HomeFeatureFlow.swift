import Foundation

/// Feature flow for the Home landing surface.
///
/// Owns the `HomeFeatureState` and processes `HomeFeatureEvent` values emitted
/// by `HomePageView`. Home is placeholder-only in the first vertical slice — no
/// data workers or dashboard loading are part of this phase.
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
            break // Placeholder-only. No dashboard data is loaded in this phase.
        }
    }
}
