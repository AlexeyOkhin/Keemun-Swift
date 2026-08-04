import Foundation

/// `Update` is a pure function, so it carries no state of its own and is safe to share between threads.
/// That also lets it be stored in a `static let` without any concurrency annotations at the call site.
public struct Update<State, Msg, Effect>: Sendable {
    public let run: @Sendable (Msg, State) -> Next<State, Effect>
    
    public init(_ run: @escaping @Sendable (Msg, State) -> Next<State, Effect>) {
        self.run = run
    }
}
