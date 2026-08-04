import XCTest
import Combine
import CombineExpectations
@testable import Keemun

/// The expectations below are inverted on purpose: they wait for one more state than the correct behaviour
/// produces, so an effect that is executed twice shows up as an extra state and fails the test.
final class RoutingTest: XCTestCase {
    private let timeout: TimeInterval = 0.5
    
    /// Every effect must reach the handler that accepts it, and each one exactly once.
    func testEachEffectIsHandledOnceByItsOwnHandler() throws {
        let store = Keemun.Store(
            routingStoreParams(
                effectHandlers: [
                    routingHandler(for: .first, answering: .firstWasHandled),
                    routingHandler(for: .second, answering: .secondWasHandled)
                ]
            )
        )
        let recorder = store.state.record()
        
        store.dispatch(.run([.first, .second]))
        let actual = try wait(for: recorder.prefix(5).inverted, timeout: timeout)
        
        XCTAssertEqual(actual, [
            RoutingState(),                              // Initial state
            RoutingState(),                              // .run produced the effects
            RoutingState(firstCount: 1),
            RoutingState(firstCount: 1, secondCount: 1)
        ])
    }
    
    /// The order of the handlers must not change how many times an effect is executed.
    func testHandlerOrderDoesNotAffectResult() throws {
        let store = Keemun.Store(
            routingStoreParams(
                effectHandlers: [
                    routingHandler(for: .second, answering: .secondWasHandled),
                    routingHandler(for: .first, answering: .firstWasHandled)
                ]
            )
        )
        let recorder = store.state.record()
        
        store.dispatch(.run([.first, .second]))
        let actual = try wait(for: recorder.prefix(5).inverted, timeout: timeout)
        
        XCTAssertEqual(actual.last, RoutingState(firstCount: 1, secondCount: 1))
        XCTAssertEqual(actual.count, 4)
    }
    
    /// A handler that declines every effect must not swallow it.
    func testDecliningHandlerPassesEffectOn() throws {
        let store = Keemun.Store(
            routingStoreParams(
                effectHandlers: [
                    EffectHandler(routing: { _ in nil }),
                    routingHandler(for: .first, answering: .firstWasHandled)
                ]
            )
        )
        let recorder = store.state.record()
        
        store.dispatch(.run([.first]))
        let actual = try wait(for: recorder.prefix(4).inverted, timeout: timeout)
        
        XCTAssertEqual(actual, [
            RoutingState(),
            RoutingState(),
            RoutingState(firstCount: 1)
        ])
    }
    
    /// Handlers built with the original API accept everything, so the first one wins and no effect is duplicated.
    func testLegacyHandlersDoNotDuplicateEffects() throws {
        let store = Keemun.Store(
            routingStoreParams(
                effectHandlers: [
                    legacyHandler(answering: .firstWasHandled),
                    legacyHandler(answering: .firstWasHandled)
                ]
            )
        )
        let recorder = store.state.record()
        
        store.dispatch(.run([.first]))
        let actual = try wait(for: recorder.prefix(4).inverted, timeout: timeout)
        
        XCTAssertEqual(actual, [
            RoutingState(),
            RoutingState(),
            RoutingState(firstCount: 1)
        ])
    }
    
    /// `processing` keeps its original signature and still reports an operation for every effect.
    func testProcessingRemainsAvailableForEveryEffect() throws {
        let handler = routingHandler(for: .first, answering: .firstWasHandled)
        
        XCTAssertNotNil(handler.routing(.first))
        XCTAssertNil(handler.routing(.second))
        
        switch handler.processing(.second) {
        case .publisher:
            break
            
        case .task:
            XCTFail("A declined effect is expected to be reported as an empty publisher")
        }
    }
}
