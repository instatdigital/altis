import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Altis iOS bootstrap")
            Image(systemName: "checklist")
                .imageScale(.large)
        }
        .padding(24)
    }
}

#Preview {
    RootView()
}
