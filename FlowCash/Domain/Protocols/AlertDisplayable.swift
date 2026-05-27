import Foundation

@MainActor
protocol AlertDisplayable: AnyObject {
    var alert: AppAlert? { get set }
}
