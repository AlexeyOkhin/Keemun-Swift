import Combine
import Foundation

/// A thread-safe container for the subscriptions created by a `Store`.
///
/// A store registers subscriptions from two places that can run at the same time: the thread that creates the
/// store, while the effects returned by `Start` are being processed, and the store's internal queue, while the
/// messages produced by those effects are being handled.
final class CancellableBag: @unchecked Sendable {
    private let lock = NSLock()
    private var cancellables: Set<AnyCancellable> = []
    
    func insert(_ cancellable: AnyCancellable) {
        lock.lock()
        defer { lock.unlock() }
        cancellables.insert(cancellable)
    }
    
    func removeAll() {
        lock.lock()
        defer { lock.unlock() }
        cancellables.removeAll()
    }
}
