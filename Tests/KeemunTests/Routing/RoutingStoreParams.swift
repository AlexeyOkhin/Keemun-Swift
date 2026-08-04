import Combine
import Foundation
@testable import Keemun

/// Counts how many times each effect was actually executed by a handler.
struct RoutingState: Equatable {
    var firstCount: Int = 0
    var secondCount: Int = 0
}

enum RoutingMsg {
    case run([RoutingEffect])
    case firstWasHandled
    case secondWasHandled
}

enum RoutingEffect: Equatable {
    case first
    case second
}

func routingUpdate() -> Update<RoutingState, RoutingMsg, RoutingEffect> {
    return Update { msg, state in
        switch msg {
        case let .run(effects):
            return .next(state, effects: effects)

        case .firstWasHandled:
            return .next(state) { $0.firstCount += 1 }

        case .secondWasHandled:
            return .next(state) { $0.secondCount += 1 }
        }
    }
}

/// A handler that accepts a single effect and passes everything else on to the next handler.
func routingHandler(
    for handledEffect: RoutingEffect,
    answering msg: RoutingMsg
) -> EffectHandler<RoutingEffect, RoutingMsg> {
    return EffectHandler(routing: { effect in
        guard effect == handledEffect else { return nil }
        return .publisher(Just(msg).eraseToAnyPublisher())
    })
}

/// A handler written against the original API, which cannot decline an effect.
func legacyHandler(answering msg: RoutingMsg) -> EffectHandler<RoutingEffect, RoutingMsg> {
    return EffectHandler { _ in
        .publisher(Just(msg).eraseToAnyPublisher())
    }
}

/// Effects are launched by `.run` rather than by `Start`, so that a test can subscribe to the state
/// before anything is dispatched and observe the whole sequence.
func routingStoreParams(
    effectHandlers: [EffectHandler<RoutingEffect, RoutingMsg>]
) -> StoreParams<RoutingState, RoutingMsg, RoutingEffect> {
    return StoreParams(
        start: Start { .next(.init()) },
        update: routingUpdate(),
        effectHandlers: effectHandlers
    )
}
