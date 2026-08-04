import Foundation
import Combine

/// The entity controls all entities and initiates the message processing and side effect mechanism.
public final class Store<State, Msg, Effect> : @unchecked Sendable {
    private let params: StoreParams<State, Msg, Effect>
    
    private let _state: CurrentValueSubject<State, Never>
    
    private let _messages = PassthroughSubject<Msg, Never>()
    private var cancellables: Set<AnyCancellable> = []
    
    public var currentState: State { self._state.value }
    public let state: AnyPublisher<State, Never>
    
    public init(_ params: StoreParams<State, Msg, Effect>) {
        self.params = params
        
        let startNext = self.params.start.run()
        let defaultState = startNext.state
        let startEffects = startNext.effects
        
        self._state = CurrentValueSubject(defaultState)
        self.state = self._state.eraseToAnyPublisher()
        
        let observeMessagesQueue = DispatchQueue(label: "keemun.observeMessagesQueue", qos: .userInitiated)
        self._messages
            .receive(on: observeMessagesQueue)
            .buffer(size: .max, prefetch: .keepFull, whenFull: .dropOldest)
            .sink { [weak self] msg in
                guard let self else { return }
                observeMessages(state: _state.value, msg: msg)
            }
            .store(in: &self.cancellables)
        self.effectProcess(startEffects, dispatch: self.dispatch)
    }
    
    /// Sending messages asynchronously.
    public lazy var dispatch: Dispatch<Msg> = { [weak self] msg in
        guard let self else { return }
        _messages.send(msg)
    }

    private func observeMessages(state: State, msg: Msg) {
        let next = self.params.update.run(msg, state)
        self._state.send(next.state)
        effectProcess(next.effects, dispatch: self.dispatch)
    }
    
    /// Each effect is offered to the handlers in the order they were registered and is executed by the first
    /// handler that accepts it, so an effect is never handled more than once.
    private func effectProcess(_ effects: [Effect], dispatch: @escaping Dispatch<Msg>) {
        for effect in effects {
            for effectHandler in self.params.effectHandlers {
                guard let operation = effectHandler.routing(effect) else { continue }
                switch operation {
                case let .publisher(anyPublisher):
                    anyPublisher
                        .sink { msg in dispatch(msg) }
                        .store(in: &cancellables)

                case let .task(priority, operation):
                    Task(priority: priority) {
                        await operation { msg in dispatch(msg) }
                    }
                }
                break
            }
        }
    }

    deinit {
        cancellables.removeAll()
    }
}
