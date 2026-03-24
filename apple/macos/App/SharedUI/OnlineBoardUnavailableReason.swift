import Foundation

/// Reason why an online board surface is currently unavailable.
///
/// Feature states use this value to drive the correct UI message instead of
/// silently clearing `isLoading`. Per `docs/SYNC_RULES.md`: online boards MUST
/// surface unavailable, blocked, or reconnect-required state when network or
/// auth is missing — they MUST NOT fall back to local durable writes.
enum OnlineBoardUnavailableReason {
    /// Network is not reachable at this moment.
    case networkUnavailable
    /// The user is not authenticated for online board access.
    case notAuthenticated
    /// Online board support is not yet implemented (Phase 14 stub).
    case notImplemented
}
