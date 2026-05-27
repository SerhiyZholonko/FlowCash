import Foundation

@MainActor
protocol ErrorDisplayable: AnyObject {
    var error: Error? { get set }
}
