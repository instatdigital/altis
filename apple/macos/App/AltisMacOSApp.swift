import SwiftUI

@main
struct AltisMacOSApp: App {

    /// Application-level dependencies.
    ///
    /// Starts as `nil`; populated by an async `.task` on `AppLaunchView`.
    /// A fatal error is raised if the local store cannot be opened because
    /// the app cannot function without SQLite-backed offline persistence.
    @State private var environment: AppEnvironment?

    var body: some Scene {
        WindowGroup {
            AppLaunchView(environment: $environment)
        }
    }
}
