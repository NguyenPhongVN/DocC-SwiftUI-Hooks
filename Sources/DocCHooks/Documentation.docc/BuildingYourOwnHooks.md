# Building Your OwnHooks

A SwiftUI implementation of React Hooks. Enhances reusability of stateful logic and gives state and lifecycle to function view.

@Metadata {
  @PageImage(purpose: card, source: "gettingStarted-card", alt: "The profile images for a regular sloth and an ice sloth.")
}

## PropertyWrapper


### HState

* <doc:HState> Like `@State` in SwiftUI, but init inside `HookScope`. See Also `useState`.

```swift
@propertyWrapper
public struct HState<Node> {

  internal let _value: Binding<Node>

  public init(wrappedValue: @escaping () -> Node) {
    _value = useState(wrappedValue())
  }

  public init(wrappedValue: Node) {
    _value = useState(wrappedValue)
  }

  public init(wrappedValue: @escaping () -> Binding<Node>) {
    _value = wrappedValue()
  }

  public init(wrappedValue: Binding<Node>) {
    _value = wrappedValue
  }

  public var wrappedValue: Node {
    get {
      _value.wrappedValue
    }
    nonmutating set {
      _value.wrappedValue = newValue
    }
  }
}
```

* How to use HState?

```swift
HookScope {

  @HState var state = 0
  
  @HState<Int> var otherState = {
    let initialState = computation() // Int
    return initialState
  }

}
```
### HRef

<doc:HRef> A propertyWrapper for `useRef` hook.

```swift
@propertyWrapper
public struct HRef<Node> {

  private let _value: RefObject<Node>

  @SAnyRef
  internal var _ref: ((Node) -> Void)? = nil

  public init(wrappedValue: @escaping () -> Node) {
    _value = useRef(wrappedValue())
  }

  public init(wrappedValue: Node) {
    _value = useRef(wrappedValue)
  }

  public var wrappedValue: Node {
    get {
      _value.current
    }
    nonmutating set {
      _value.current = newValue
      if let value = _ref {
        value(newValue)
      }
    }
  }

  public var projectedValue: Self {
    self
  }

  public var value: RefObject<Node> {
    _value
  }

  public func send(_ node: Node) {
    value.current = node
  }

  public func onUpdated(_ onUpdate: @escaping (Node) -> Void) -> Self {
    _ref = onUpdate
    return self
  }
}

```

* How to use HRef?

```swift
HookScope {
  @HRef var state = 0
}
```

### HContext

<doc:HContext> A propertyWrapper for `useContext` hook.

```swift
@propertyWrapper
  public struct HContext<Node> {

  public typealias Context = Hooks.Context<Node>

  public init(wrappedValue: @escaping () -> Context.Type) {
    self.wrappedValue = wrappedValue()
  }

  public init(wrappedValue: Context.Type) {
    self.wrappedValue = wrappedValue
  }

  public var wrappedValue: Context.Type

  public var projectedValue: Self {
    self
  }

  public var value: Node {
    useContext(wrappedValue)
  }
}
```

* How to use HContext?

```swift
HookScope {
  @HContext
  var todoContext = TodoContext.self
  let todos = $todoContext.value
}

```

### HMemo

<doc:HMemo> A propertyWrapper for `useMemo` hook.

```swift
@propertyWrapper
  public struct HMemo<Node> {

  private let initialNode: () -> Node

  private let updateStrategy: HookUpdateStrategy

  public init(
    wrappedValue: Node,
    _ updateStrategy: HookUpdateStrategy = .once
  ) {
    initialNode = { wrappedValue }
    self.updateStrategy = updateStrategy
  }

  public init(
    wrappedValue: @escaping () -> Node,
    _ updateStrategy: HookUpdateStrategy = .once
  ) {
    initialNode = wrappedValue
    self.updateStrategy = updateStrategy
  }

  public var wrappedValue: Node {
    useMemo(updateStrategy, initialNode)
  }

  public var projectedValue: Self {
    self
  }

  public var value: Node {
    wrappedValue
  }
}
```

* How to use HMemo?

```swift
HookScope {
  @HState var state = 0

  @HMemo(.preserved(by: state))
  var randomColor = Color(hue: .random(in: 0...1), saturation: 1, brightness: 1)

}

```

### HEnvironment

<doc:HEnvironment> A propertyWrapper for `useEnvironment` hook.

```swift
@propertyWrapper
  public struct HEnvironment<Value> {

  public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
    self.wrappedValue = useEnvironment(keyPath)
  }

  public var wrappedValue: Value

  public var projectedValue: Self {
    self
  }

  public var value: Value {
    wrappedValue
  }
}
```

* How to use HEnvironment?

```swift
HookScope {
  @HEnvironment(\.dismiss)
  var dismiss
}
```

## Building from other Hook

### useValueChanged

Watches a value and triggers a callback whenever the value changed.

`useValueChanged` takes a valueChange callback and calls it whenever value changed. valueChange will not be called on the first useValueChanged call.

`useValueChanged` can also be used to interpolate Whenever useValueChanged is called with a different value, calls valueChange. The value returned by useValueChanged is the latest returned value of valueChange or null.

```swift
@discardableResult
public func useValueChanged<Node: Equatable>(
  _ value: Node,
  callBack: @escaping (Node, Node) -> Void
) -> Node {
  @HRef
  var cache = value
  useLayoutEffect(.preserved(by: value)) {
      if cache != value {
      callBack(cache, value)
      cache = value
    }
    return nil
  }
  return cache
}

```
* How to use useValueChanged?

```swift
HookScope {

  @HState
  var state = 0

  let newValue = useValueChanged(state) { old, new in
    log.info("oldValue: \(old)")
    log.info("newValue: \(new)")
  }

  VStack {
    Stepper(value: $state) {
      Text(newValue.description)
    }
  }
  .padding()
  .font(.largeTitle)
}

```
### useCount

```swift
public func useCount(
  _ updateStrategy: HookUpdateStrategy = .once
) -> Int {
  @HState var count = 0
  useMemo(updateStrategy) {
    count += 1
  }
  return count
}

```
* How to use useCount?

```swift
HookScope {
  @HState var count = 0
  let countChanged = useCount(count)
}

```

## Building Custom Hooks.

```swift
// MARK: Call operation only running `refresher` action, It will updateUI result status AsyncPhase.

/// A hook to use the most recent phase of the passed non-throwing asynchronous operation, and a `perform` function to call the it at arbitrary timing.
///
///     let (phase, refresh) = useAsyncRefresh {
///         try! await URLSession.shared.data(from: url)
///     }
///
/// - Parameter operation: A closure that produces a resulting value asynchronously.
/// - Returns: A tuple of the most recent async phase and its perform function.

@discardableResult
public func useAsyncRefresh<Output>(
  _ operation: @escaping @MainActor () async -> Output
) -> (phase: AsyncPhase<Output, Never>, refresher: AsyncCompletion) {
  useHook(AsyncRefreshHook(operation: operation))
}

/// A hook to use the most recent phase of the passed throwing asynchronous operation, and a `perform` function to call the it at arbitrary timing.
///
///     let (phase, refresh) = useAsyncRefresh {
///         try await URLSession.shared.data(from: url)
///     }
///
/// - Parameter operation: A closure that produces a resulting value asynchronously.
/// - Returns: A most recent async phase.
@discardableResult
public func useAsyncRefresh<Output>(
_ operation: @escaping @MainActor () async throws -> Output
) -> (phase: AsyncPhase<Output, Error>, refresher: ThrowingAsyncCompletion) {
  useHook(AsyncThrowingRefreshHook(operation: operation))
}

private struct AsyncRefreshHook<Output>: Hook {

  typealias State = _HookRef

  typealias Phase = AsyncPhase<Output, Never>

  typealias Value = (phase: Phase, refresher: AsyncCompletion)

  let updateStrategy: HookUpdateStrategy? = .once

  let operation: @MainActor () async -> Output

  func makeState() -> State {
    State()
  }

  func value(coordinator: Coordinator) -> Value {
    let phase = coordinator.state.phase
    let refresher: AsyncCompletion = {
      guard !coordinator.state.isDisposed else {
        return
      }
      coordinator.state.task = Task { @MainActor in
        let output = await operation()
        if !Task.isCancelled && !coordinator.state.isDisposed {
          coordinator.state.phase = .success(output)
          coordinator.updateView()
        }
      }
    }
    return (phase: phase, refresher: refresher)
  }

  func updateState(coordinator: Coordinator) {
    guard !coordinator.state.isDisposed else {
      return
    }
  }

  func dispose(state: State) {
    state.dispose()
  }
}

private extension AsyncRefreshHook {
// MARK: State
  final class _HookRef {

    var phase: Phase = .pending

    var task: Task<Void, Never>? {
      didSet {
        oldValue?.cancel()
      }
    }

    var isDisposed = false

    func dispose() {
      task = nil
      isDisposed = true
    }
  }
}

private struct AsyncThrowingRefreshHook<Output>: Hook {

  typealias State = _HookRef

  typealias Phase = AsyncPhase<Output, Error>

  typealias Value = (phase: Phase, refresher: ThrowingAsyncCompletion)

  let updateStrategy: HookUpdateStrategy? = .once

  let operation: @MainActor () async throws -> Output

  func makeState() -> State {
    State()
  }

  func value(coordinator: Coordinator) -> Value {
    let phase = coordinator.state.phase
    let refresher: ThrowingAsyncCompletion = {
      guard !coordinator.state.isDisposed else {
        return
      }
      coordinator.state.task = Task { @MainActor in
        guard !coordinator.state.isDisposed else {
          return
        }
        let phase: AsyncPhase<Output, Error>
      do {
          let output = try await operation()
          phase = .success(output)
        } catch {
          phase = .failure(error)
        }
        if !Task.isCancelled && !coordinator.state.isDisposed {
          coordinator.state.phase = phase
          coordinator.updateView()
        }
      }
    }
    return (phase: phase, refresher: refresher)
  }

  func updateState(coordinator: Coordinator) {
    guard !coordinator.state.isDisposed else {
      return
    }
  }

  func dispose(state: State) {
    state.isDisposed = true
  }
}

private extension AsyncThrowingRefreshHook {
// MARK: State
  final class _HookRef {

    var phase: Phase = .pending

    var task: Task<Void, Never>? {
      didSet {
        oldValue?.cancel()
      }
    }

    var isDisposed = false

    func dispose() {
      task = nil
      isDisposed = true
    }
  }
}
```

### useSetState

```swift
/// A hook to use a `Binding<Node>` wrapping current state to be updated by setting a new state to `wrappedValue`.
/// Triggers a view update when the state has been changed.
///
///     let (count, setCount) = useSetState {
///         let initialNode = expensiveComputation()
///         return initialNode
///     }
///
///     Button("Increment") {
///         setCount(count + 1)
///     }
///
/// - Parameter initialNode: A closure creating an initial state. The closure will only be called once, during the initial render.
/// - Returns: A `Binding<Node>` wrapping current state.
public func useSetState<Node>(
  _ initialNode: @escaping () -> Node
) -> (Node, (Node) -> Void) {
  useHook(SetStateHook(initialNode: initialNode))
}

/// A hook to use a `Binding<Node>` wrapping current state to be updated by setting a new state to `wrappedValue`.
/// Triggers a view update when the state has been changed.
///
///     let (count, setCount) = useSetState(0)
///
///     Button("Increment") {
///         setCount(count + 1)
///     }
///
/// - Parameter initialNode: An initial state.
/// - Returns: A `Binding<Node>` wrapping current state.
public func useSetState<Node>(
_ initialNode: Node
) -> (Node, (Node) -> Void) {
  useSetState {
    initialNode
  }
}


private struct SetStateHook<Node>: Hook {

  typealias State = _HookRef

  typealias Value = (Node, (Node) -> Void)

  let updateStrategy: HookUpdateStrategy? = .once

  let initialNode: () -> Node

  func makeState() -> State {
    State(initialNode())
  }

  func value(coordinator: Coordinator) -> Value {
    let node = coordinator.state.node
    let setNode: (Node) -> Void = {
      guard !coordinator.state.isDisposed else {
        return
      }
      coordinator.state.node = $0
      coordinator.updateView()
    }
    return (node, setNode)
  }

  func updateState(coordinator: Coordinator) {
    guard !coordinator.state.isDisposed else {
      return
    }
  }

  func dispose(state: State) {
    state.dispose()
  }
}

private extension SetStateHook {
// MARK: State
  final class _HookRef {

    var node: Node

    var isDisposed = false

    init(_ initialNode: Node) {
      self.node = initialNode
    }

    func dispose() {
      isDisposed = true
    }
  }
}

```
