import Combine
import Foundation
@testable import Keemun

struct ConcurrencyState: Equatable {
    var counter: Int = 0
}

enum ConcurrencyMsg {
    case spawned
}

enum ConcurrencyEffect: Equatable {
    /// Synchronously dispatches `count` messages as soon as the handler subscribes to it.
    case spawn(count: Int)
    /// Produces no message, but still registers a subscription inside the store.
    case noop
}

/// Every spawned message asks for one more effect, so the store keeps registering subscriptions while
/// `Start` is still being processed on the thread that created the store.
func concurrencyStoreParams(spawnCount: Int, batches: Int) -> StoreParams<ConcurrencyState, ConcurrencyMsg, ConcurrencyEffect> {
    return StoreParams(
        start: Start {
            .next(.init(), effects: Array(repeating: ConcurrencyEffect.spawn(count: spawnCount), count: batches))
        },
        update: Update { msg, state in
            switch msg {
            case .spawned:
                return .next(state, effect: .noop) { $0.counter += 1 }
            }
        },
        effectHandler: EffectHandler { effect in
            switch effect {
            case let .spawn(count):
                return .publisher(
                    (1...count).publisher
                        .map { _ in ConcurrencyMsg.spawned }
                        .eraseToAnyPublisher()
                )

            case .noop:
                return .publisher(Empty().eraseToAnyPublisher())
            }
        }
    )
}
