import Foundation

/// Events that the Home feature flow can receive.
///
/// Home is a placeholder-only landing hub in the first vertical slice.
/// Only lifecycle events are defined here; data-loading events are added
/// when Phase 5 implements the real dashboard surface.
enum HomeFeatureEvent {
    /// Emitted once when the Home page appears for the first time.
    case appeared
}
