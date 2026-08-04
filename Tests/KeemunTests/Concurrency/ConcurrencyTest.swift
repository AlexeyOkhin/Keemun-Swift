import XCTest
import Combine
import CombineExpectations
@testable import Keemun

final class ConcurrencyTest: XCTestCase {
    /// Effects returned by `Start` are processed on the thread that creates the store, while the messages they
    /// dispatch are processed on the store's internal queue. Both paths register subscriptions, so this test
    /// exercises the store's bookkeeping from two threads at once and is meant to be run under the thread sanitizer.
    func testStartEffectsAndDispatchedMessagesDoNotRace() throws {
        let spawnCount = 50
        let batches = 20
        let store = Keemun.Store(concurrencyStoreParams(spawnCount: spawnCount, batches: batches))
        
        let recorder = store.state.record()
        let states = try wait(for: recorder.availableElements, timeout: 5)
        
        XCTAssertEqual(states.last, ConcurrencyState(counter: spawnCount * batches))
    }
}
