# v2.2.0
- Added support for Swift 6 and `swift-tools-version: 6.2`.
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
