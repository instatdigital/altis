import SwiftUI

/// Launch wrapper that asynchronously initialises the app environment.
///
/// Shows a loading indicator while the SQLite store is opened and migrations
/// run, then hands off to `AppShell` once the environment is ready.
struct AppLaunchView: View {

    @Binding var environment: AppEnvironment?

    var body: some View {
        Group {
            if let environment {
                AppShell(environment: environment)
            } else {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            guard environment == nil else { return }
            do {
                environment = try await AppEnvironment.production()
            } catch {
                fatalError("Failed to initialise local store: \(error)")
            }
        }
    }
}

// MARK: - Project list page (legacy alias kept for existing preview)

struct RootView: View {
    @State private var env: AppEnvironment?
    var body: some View {
        AppLaunchView(environment: $env)
    }
}
