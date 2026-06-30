import SwiftUI
import SwiftData

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        HomeView()
            .onAppear { triggerCloudKitSync() }
    }

    private func triggerCloudKitSync() {
        // Примусово запитує актуальний стан від CloudKit при відкритті
        try? modelContext.save()
    }
}

#Preview {
    AppRootView()
        .environment(AccountSelection())
        .environment(DeepLinkRouter())
        .injectMockStore()
}
