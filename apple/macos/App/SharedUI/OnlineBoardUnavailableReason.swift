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

enum OnlineBoardAccessError: Error, Sendable {
    case networkUnavailable
    case notAuthenticated
    case notImplemented
}

extension OnlineBoardUnavailableReason {
    init(error: Error) {
        if let accessError = error as? OnlineBoardAccessError {
            switch accessError {
            case .networkUnavailable: self = .networkUnavailable
            case .notAuthenticated: self = .notAuthenticated
            case .notImplemented: self = .notImplemented
            }
            return
        }

        let nsError = error as NSError
        let authErrorCodes: Set<Int> = [
            NSURLErrorUserAuthenticationRequired,
            NSURLErrorUserCancelledAuthentication
        ]
        if nsError.domain == NSURLErrorDomain && authErrorCodes.contains(nsError.code) {
            self = .notAuthenticated
        } else if nsError.domain == NSURLErrorDomain {
            self = .networkUnavailable
        } else {
            self = .networkUnavailable
        }
    }

    var message: String {
        switch self {
        case .networkUnavailable: return "Network is not available."
        case .notAuthenticated: return "Sign in to access online boards."
        case .notImplemented: return "Online boards are not implemented yet."
        }
    }
}
