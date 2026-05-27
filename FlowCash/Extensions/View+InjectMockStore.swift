import SwiftUI
import FactoryKit

extension View {
    func injectMockStore() -> some View {
        onAppear {
            Container.shared.dataStore.register { MockDataStore() }
        }
    }
}
