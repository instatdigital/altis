import Foundation

/// Stateless validator for the canonical board-stage invariants.
///
/// Invariants (from `docs/TYPES_AND_CONTRACTS.md`):
/// - Every staged board MUST contain at least three stages.
/// - Every staged board MUST contain exactly one `terminalSuccess` stage.
/// - Every staged board MUST contain exactly one `terminalFailure` stage.
/// - A board MUST contain at least one `regular` stage.
/// - Terminal stages MUST NOT be deleted.
/// - Deleting a non-terminal stage MUST move its tasks to the first available stage.
///
/// Call `validate(_:)` before persisting a mutated stage list. Callers receive a
/// typed `Result` describing which invariant was violated rather than a raw assertion.
enum BoardStageInvariants {

    // MARK: - Validation

    /// Validates that `stages` satisfies all board-stage invariants.
    ///
    /// - Parameter stages: The complete ordered stage list for a single board.
    /// - Returns: `.success(())` when all invariants hold; `.failure` with a descriptive
    ///   `Violation` when at least one invariant is broken. Only the first detected
    ///   violation is returned.
    static func validate(_ stages: [BoardStage]) -> Result<Void, Violation> {
        guard stages.count >= 3 else {
            return .failure(.tooFewStages(count: stages.count))
        }

        let successCount = stages.filter { $0.kind == .terminalSuccess }.count
        guard successCount == 1 else {
            return .failure(.wrongTerminalSuccessCount(count: successCount))
        }

        let failureCount = stages.filter { $0.kind == .terminalFailure }.count
        guard failureCount == 1 else {
            return .failure(.wrongTerminalFailureCount(count: failureCount))
        }

        let regularCount = stages.filter { $0.kind == .regular }.count
        guard regularCount >= 1 else {
            return .failure(.noRegularStages)
        }

        return .success(())
    }

    /// Validates that a stage may be deleted from `stages`.
    ///
    /// Terminal stages MUST NOT be deleted. Call this before removing a stage.
    static func canDelete(stage: BoardStage, from stages: [BoardStage]) -> Result<Void, Violation> {
        if stage.isTerminal {
            return .failure(.terminalStageDeletionAttempted(stageId: stage.stageId))
        }
        // After removal the remaining list must still pass full validation.
        let remaining = stages.filter { $0.stageId != stage.stageId }
        return validate(remaining)
    }

    // MARK: - Violation

    /// A description of which board-stage invariant was violated.
    enum Violation: Error, CustomStringConvertible {
        case tooFewStages(count: Int)
        case wrongTerminalSuccessCount(count: Int)
        case wrongTerminalFailureCount(count: Int)
        case noRegularStages
        case terminalStageDeletionAttempted(stageId: BoardStageID)

        var description: String {
            switch self {
            case .tooFewStages(let count):
                return "Board must have at least 3 stages, but has \(count)."
            case .wrongTerminalSuccessCount(let count):
                return "Board must have exactly 1 terminalSuccess stage, but has \(count)."
            case .wrongTerminalFailureCount(let count):
                return "Board must have exactly 1 terminalFailure stage, but has \(count)."
            case .noRegularStages:
                return "Board must have at least 1 regular stage."
            case .terminalStageDeletionAttempted(let stageId):
                return "Cannot delete terminal stage \(stageId.rawValue)."
            }
        }
    }
}
