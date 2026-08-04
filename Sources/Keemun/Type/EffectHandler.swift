import Combine
import Dispatch
import Foundation

public typealias Dispatch<Msg> = @Sendable (Msg) -> Void

public struct EffectHandler<Effect, Msg> {
    /// Maps an effect to the operation that handles it, or to `nil` if this handler does not handle the effect.
    ///
    /// `Store` offers every effect to the handlers in order and stops at the first one that returns a non-`nil`
    /// operation, so returning `nil` is how a handler passes an effect on to the next handler.
    public let routing: (Effect) -> Operation<Msg>?
    
    /// Maps an effect to the operation that handles it.
    ///
    /// Effects that the handler does not handle are reported as an operation that completes without dispatching
    /// anything. Prefer ``routing`` when you need to tell those two cases apart.
    public var processing: (Effect) -> Operation<Msg> {
        let routing = self.routing
        return { effect in
            routing(effect) ?? .publisher(Empty().eraseToAnyPublisher())
        }
    }
    
    /// Creates a handler that handles every effect.
    ///
    /// Use ``init(routing:)`` instead when the store is configured with several handlers and this one is
    /// responsible only for a subset of the effects.
    public init(_ processing: @escaping (Effect) -> Operation<Msg>) {
        self.routing = { effect in processing(effect) }
    }
    
    /// Creates a handler that handles only the effects for which `routing` returns a non-`nil` operation.
    public init(routing: @escaping (Effect) -> Operation<Msg>?) {
        self.routing = routing
    }
    
    public enum Operation<Message> {
        case publisher(AnyPublisher<Message, Never>)
        case task(TaskPriority? = nil, @Sendable (Dispatch<Message>) async -> Void)
    }
}

public extension EffectHandler {
    func map<OutMsg>(_ transform: @escaping @Sendable (Msg) -> OutMsg) -> EffectHandler<Effect, OutMsg> {
        return EffectHandler<Effect, OutMsg>(routing: { effect in
            guard let operation = self.routing(effect) else { return nil }
            switch operation {
            case let .publisher(anyPublisher):
                return .publisher(
                    anyPublisher
                        .map(transform)
                        .eraseToAnyPublisher()
                )

            case let .task(priority, operation):
                return .task(priority) { dispatch in
                    await operation { msg in dispatch(transform(msg)) }
                }
            }
        })
    }
}
