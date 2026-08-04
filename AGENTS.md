# Keemun-Swift

Swift-фреймворк, реализующий The Elm Architecture (однонаправленный поток данных) для SwiftUI.
Репозиторий — это библиотека, а не приложение. Приложение `Samples` существует только для демонстрации.

## Карта репозитория

| Путь | Что это |
|---|---|
| `Sources/Keemun/` | Единственный исходник библиотеки, модуль `Keemun` |
| `Tests/KeemunTests/` | Тесты на XCTest поверх `CombineExpectations` |
| `Samples/Samples.xcodeproj` | Демо-приложение SwiftUI, подключает библиотеку как local SPM package |
| `Templates/Keemun Feature.xctemplate/` | 16 Xcode-шаблонов генерации фичи. Устанавливаются через `make install_templates` |
| `docs/` | Только картинки для README (`keemun.drawio` — исходник схем) |
| `Package.swift`, `Keemun.podspec` | Две системы дистрибуции, обе описывают один и тот же набор файлов |

## Ядро библиотеки

`Sources/Keemun/` состоит из трёх слоёв:

- `Type/` — примитивы: `Start`, `Update`, `EffectHandler`, `StateTransform`. Все четыре — это структуры-обёртки над замыканием, без состояния.
- `Store/` — `Store` (единственный класс с изменяемым состоянием, крутит цикл msg → update → effect) и `StoreParams` (контейнер `Start` + `Update` + `[EffectHandler]`).
- `Feature/` — `KeemunFeature` (протокол, связывает `storeParams` и `featureParams`), `FeatureParams` (маппинг `State → ViewState` и `ExternalMsg → Msg`), `KeemunConnector` (`ObservableObject`-обёртка для SwiftUI; файл называется `KeemnConnector.swift` — опечатка в имени файла).
- `Next.swift` — результат `Update`: новый `State` + массив `Effect`, плюс DSL-хелперы `.next(...)`.
- `Msg.swift` — `PairMsg<ExternalMsg, InternalMsg>` и `Update.combine`, разделяющие сообщения от UI и от бизнес-логики.

Поток данных: `dispatch(msg)` → `Store._messages` → `Update.run(msg, state)` → `Next` → новый state в `CurrentValueSubject` + эффекты в `EffectHandler` → `dispatch` новых сообщений.

## Как устроена фича

Одна фича — это `struct XFeature: KeemunFeature`, разложенный по расширениям в отдельных файлах (см. `Samples/Samples/Features/Counter/` и `Templates/`):

- `X+StoreParams.swift` — объявление типа, `storeParams`, вложенный `State`, `InputEvent`/`OutputEvent`.
- `X+Update.swift` — `externalUpdate`, `internalUpdate`, enum'ы `ExternalMsg`/`InternalMsg`.
- `X+Effect.swift` — `effectHandler()`, enum `Effect`.
- `X+FeatureParams.swift` — `featureParams`, `ViewState`.
- `X+UI.swift` — публичная `XFeatureView` поверх `KeemunConnector` и приватная `MainView`, принимающая только `state` и замыкания.

Оси именования шаблонов: `Single`/`Multi` (один файл или разнесённые `Update`/`Effect`), `Unified`/`Distributed` (единый `Msg` или `PairMsg`), суффиксы `HasInputEvent`/`HasOutputEvent` (общение с внешним миром через `Effect.observeInputEvent` / `Effect.sendOutputEvent`).

## Правила при изменении кода

- `Update` обязан оставаться чистой функцией: никакого I/O, времени, рандома, обращений к синглтонам. Всё это — только в `EffectHandler`.
- `State` — структура со значимой семантикой; мутация только через `.next(state) { $0.field = ... }`.
- `ViewState` — отдельный тип, готовый к отрисовке (строки, а не числа). SwiftUI никогда не видит `State`.
- Всё, что фича шлёт наружу, идёт через `OutputEvent`, а не через прямые вызовы. Всё, что приходит извне, — через `InputEvent` и `.publisher`.
- Регистрируешь в `StoreParams` несколько `effectHandlers` — создавай их через `EffectHandler(routing:)` и возвращай `nil` для чужих эффектов. Эффект достаётся первому принявшему обработчику; обработчик из `init(_:)` принимает всё и заберёт эффекты у следующих за ним.
- Публичный API — исходно source-stable: изменение сигнатур `Store`, `StoreParams`, `FeatureParams`, `KeemunConnector` ломает пользователей. Помечай устаревшее через `@available(*, deprecated, message:)`, как сделано с `Next.Mutable`.
- Изменил `Sources/Keemun/**`? Синхронно обнови README, шаблоны в `Templates/` и `Samples/` — примеры в README скопированы из `Samples/Samples/Features/Counter/` и должны оставаться компилируемыми.
- Меняешь публичный API — добавь запись в `CHANGELOG.md` и подними версию в `Keemun.podspec` и в обеих инструкциях по установке в README.

## Команды

```bash
swift build                 # сборка библиотеки
swift test                  # тесты, должны проходить без варнингов
make install_templates      # установить Xcode-шаблоны в ~/Library/Developer/Xcode/Templates
```

Тесты не должны опираться на `XCTestExpectation` с таймаутом: для проверки последовательности состояний
используй `store.state.record()` и `wait(for: recorder.prefix(n), timeout:)` из `CombineExpectations`.

После изменений в `Store` прогоняй `swift test --sanitize=thread` — обычный `swift test` гонки не ловит.
Вывод должен быть без строк `WARNING: ThreadSanitizer`.

Демо-приложение собирается только из Xcode: `Samples/Samples.xcodeproj`, схема `Samples`.

## Известные проблемы (не считать за баг в своём коде)

- В репозитории нет git-тегов, поэтому ни SPM, ни CocoaPods не увидят версию из `Keemun.podspec`, пока тег не проставлен.
- `Store` помечен `@unchecked Sendable`, и убрать это нельзя: мешают `CurrentValueSubject`/`PassthroughSubject` и замыкания внутри `StoreParams`, которые не `Sendable`. Ограничение дженериков `State`/`Msg`/`Effect` на `Sendable` эту причину не устраняет, поэтому его не добавляли. Инвариант, за счёт которого аннотация корректна, описан в комментарии к классу — при правках `Store` его нужно сохранять.
- Подписки в `Store` не очищаются от завершённых: `CancellableBag` растёт, пока живёт стор.
- Отменить незавершённый эффект нельзя: `Task` из ветки `.task` нигде не хранится.
- Композиции фич нет — вложить дочернюю фичу в родительский `Store` нечем, экраны из нескольких блоков собираются из отдельных `Store` через `InputEvent`/`OutputEvent`.

