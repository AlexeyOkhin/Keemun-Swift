import Foundation

/// `Start` is a pure function, so it carries no state of its own and is safe to share between threads.
public struct Start<State, Effect>: Sendable {
    public let run: @Sendable () -> Next<State, Effect>
    
    public init(_ run: @escaping @Sendable () -> Next<State, Effect>) {
        self.run = run
    }
}
