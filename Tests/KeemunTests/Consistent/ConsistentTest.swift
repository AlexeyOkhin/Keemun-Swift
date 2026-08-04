import XCTest
import Combine
import CombineExpectations
@testable import Keemun

final class ConsistentTest: XCTestCase {
    func testUpdater1() throws {
        let userId = 101
        let defaultState = ConsistentState(progress: false, loadedUser: nil)
        let msg = ConsistentMsg.loadUserById(id: userId)
        let next = consistentStoreParams().update.run(msg, defaultState)
        XCTAssertEqual(next.state, ConsistentState(progress: true, loadedUser: nil))
        XCTAssertEqual(next.effects, [ConsistentEffect.loadUser(id: userId)])
    }
    
    func testUpdater2() throws {
        let defaultState = ConsistentState(progress: true, loadedUser: nil)
        let user = ConsistentState.User(id: 101)
        let msg = ConsistentMsg.userWasLoaded(user: user)
        let next = consistentStoreParams().update.run(msg, defaultState)
        XCTAssertEqual(next.state, ConsistentState(progress: false, loadedUser: user))
        XCTAssertEqual(next.effects, [])
    }
    
    func testFull() throws {
        let store = Keemun.Store(consistentStoreParams())
        let recorder = store.state.record()
        
        let userId = 101
        store.dispatch(ConsistentMsg.loadUserById(id: userId))
        
        let actual = try wait(for: recorder.prefix(3), timeout: 1)
        
        let expected = [
            ConsistentState(progress: false, loadedUser:  nil), // Initial state
            ConsistentState(progress: true, loadedUser: nil),
            ConsistentState(progress: false, loadedUser: ConsistentState.User(id: userId))
        ]
        XCTAssertEqual(actual, expected)
    }
}
