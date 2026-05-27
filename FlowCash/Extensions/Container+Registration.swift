import FactoryKit
import SwiftData

extension Container {
    var dataStore: Factory<any DataStoreProtocol> {
        self {
            MainActor.assumeIsolated {
                SwiftDataStore(container: FlowCashApp.modelContainer)
            }
        }.singleton
    }
}
