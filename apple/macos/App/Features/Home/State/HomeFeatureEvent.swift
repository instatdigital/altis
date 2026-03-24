import Foundation

/// Events that the Home feature flow can receive.
///
/// Home is a placeholder-only landing hub in the first vertical slice.
/// Only the lifecycle appeared event is defined here.
enum HomeFeatureEvent {
    /// Emitted once when the Home page appears for the first time.
    case appeared
}
