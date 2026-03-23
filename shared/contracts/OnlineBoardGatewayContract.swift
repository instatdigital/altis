import Foundation

/// Contract for online-board transport operations.
///
/// Online boards are backend-only. No local durable storage is used.
/// When the network is unavailable, callers receive an error and surface
/// an unavailable state in the UI — they do not fall back to local writes.
///
/// This protocol lives in `shared/contracts/` because it defines the
/// cross-platform client-side boundary for backend communication.
/// Platform-specific implementations (URLSession, Alamofire, etc.) are
/// injected at the app shell level so feature flows depend only on this
/// interface, not on a concrete HTTP client.
///
/// Phase 14 will add concrete read/write methods for online boards.
/// This stub exists to mark the boundary and satisfy Phase 3 checklist
/// requirement: "Define a separate online gateway or service contract
/// for online boards."
protocol OnlineBoardGatewayContract: Sendable {
    // Online board read and write methods are defined in Phase 14.
}
