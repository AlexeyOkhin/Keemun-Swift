# v2.2.0
- Added support for Swift 6 and `swift-tools-version: 6.2`.
- Marked `Update` and `Start` as `Sendable` (their closures are `@Sendable`) and `Next` as conditionally
`Sendable`. Pure `static let` updates no longer need `nonisolated(unsafe)`.
- Fixed a data race on the store's subscription bookkeeping. Effects returned by `Start` are processed on the
thread that creates the store while the messages they dispatch are already being handled on the store's
internal queue, and both paths registered subscriptions without synchronization. Subscriptions are now kept
in a locked container, and `dispatch` is no longer a lazily initialized property.
- Added `EffectHandler.init(routing:)` and `EffectHandler.routing`, which let a handler decline an effect by
returning `nil` so that it is passed on to the next handler.
- Fixed effects being executed once per registered effect handler. An effect is now offered to the handlers in
order and executed by the first one that accepts it. Stores configured with a single effect handler are
unaffected; stores configured with several handlers no longer run the same effect more than once.
- Added the `next(_:effects:with:)` DSL that mutates state and effects in a single closure.
- Added Xcode file templates for feature generation (`make install_templates`).
- Fixed a retain cycle in input event observation.
- Renamed `Sources/KeemunSwift` to `Sources/Keemun` and `Tests/KeemunSwiftTests` to `Tests/KeemunTests`
so that directories match the target names.
- Deprecated `Next.Mutable`, use `Next.MutableState` instead.

# v2.1.0
- Fixed effect handlers not being launched for the effects returned by `Start`.

# v2.0.0
- Reworked the public API: a feature is now described by the `KeemunFeature` protocol that exposes
`storeParams` and `featureParams`.
- Replaced `SplitMsg` with `PairMsg` and added `Update.combine(externalUpdate:internalUpdate:)`.
- `KeemunConnector` is now parameterized by `ViewState` and `ExternalMsg` and is created directly
from a feature: `KeemunConnector(CounterFeature())`.
- `EffectHandler` now returns an `Operation` (`.publisher` or `.task`) instead of being a suspending
function.

# v1.0.0
First public version
