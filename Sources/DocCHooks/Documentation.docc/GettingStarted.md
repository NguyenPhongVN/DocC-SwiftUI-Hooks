# Getting Started with Hooks

A SwiftUI implementation of React Hooks. Enhances reusability of stateful logic and gives state and lifecycle to function view.

@Metadata {
  @PageImage(purpose: card, source: "gettingStarted-card", alt: "The profile images for a regular sloth and an ice sloth.")
}

## Overview

SwiftUI Hooks là một phiên bản được dịch ra của React Hooks, hắn đưa State và lifecycle vào trong View mà không phụ thuộc vào các element chỉ được phép sử dụng trong struct View  như @State hoặc @ObservedObject.
Hắn cho phép bạn sử dụng lại logic trạng thái giữa các View bằng cách xây dựng các hook (móc,gắn) tùy chỉnh được tạo bằng nhiều hook (móc,gắn).
Hơn nữa, các hook như useEffect cũng giải quyết được vấn đề thiếu vòng đời trong SwiftUI.

Code Sample

## How do you use a Hook function?

### useState

```swift
func useState<State>(_ initialState: State) -> Binding<State>
func useState<State>(_ initialState: @escaping () -> State) -> Binding<State>
```

Một hook để sử dụng State current bao bọc  Binding<State> cần được cập nhật bằng cách đặt trạng thái mới thành wrappedValue.
Kích hoạt cập nhật View khi State đã được thay đổi.

```swift

let count = useState(0)  // Binding<Int>

Button("Increment") {
  count.wrappedValue += 1
}

```

Nếu State ban đầu là kết quả của một phép tính, thay vào đó bạn có thể cung cấp một closure. Việc đóng sẽ được thực hiện một lần, trong lần render đầu tiên.

```swift
let count = useState {
let initialState = expensiveComputation() // Int
  return initialState
}                                             // Binding<Int>

Button("Increment") {
  count.wrappedValue += 1
}

```

### useEffect

```swift
func useEffect(
_ updateStrategy: HookUpdateStrategy? = nil,
_ effect: @escaping () -> (() -> Void)?
)
```

A hook to use a side effect function that is called the number of times according to the strategy specified with updateStrategy.
Optionally the function can be cancelled when this hook is disposed or when the side-effect function is called again.
Lưu ý rằng việc thực thi được hoãn lại cho đến khi các hook khác được cập nhật.

```swift
useEffect {
  print("Do side effects")

  return {
    print("Do cleanup")
  }
}

```


### useLayoutEffect

```swift
func useLayoutEffect(
_ updateStrategy: HookUpdateStrategy? = nil,
_ effect: @escaping () -> (() -> Void)?
)
```

A hook to use a side effect function that is called the number of times according to the strategy specified with updateStrategy.
Optionally the function can be cancelled when this hook is unmount from the view tree or when the side-effect function is called again.
The signature is identical to useEffect, but this fires synchronously when the hook is called.


```swift
useLayoutEffect {
  print("Do side effects")
  return nil
}

```

### useMemo

```swift
func useMemo<Value>(
_ updateStrategy: HookUpdateStrategy,
_ makeValue: @escaping () -> Value
) -> Value
```

A hook to use memoized value preserved until it is updated at the timing determined with given updateStrategy.


```swift
let random = useMemo(.once) {
  Int.random(in: 0...100)
}
```


### useRef

```swift
func useRef<T>(_ initialValue: T) -> RefObject<T>
```

A hook to use a mutable ref object storing an arbitrary value.
The essential of this hook is that setting a value to current doesn't trigger a view update.

```swift
let value = useRef("text")  // RefObject<String>

Button("Save text") {
  value.current = "new text"
}

```
### useReducer

```swift
func useReducer<State, Action>(
_ reducer: @escaping (State, Action) -> State,
initialState: State
) -> (state: State, dispatch: (Action) -> Void)

```

A hook to use the state returned by the passed reducer, and a dispatch function to send actions to update the state.
Triggers a view update when the state has been changed.

```swift
enum Action {
  case increment, decrement
}

func reducer(state: Int, action: Action) -> Int {
  switch action {
    case .increment:
      return state + 1

    case .decrement:
      return state - 1
  }
}

let (count, dispatch) = useReducer(reducer, initialState: 0)
```

### useAsync

```swift

func useAsync<Output>(
_ updateStrategy: HookUpdateStrategy,
_ operation: @escaping () async -> Output
) -> AsyncPhase<Output, Never>

func useAsync<Output>(
_ updateStrategy: HookUpdateStrategy,
_ operation: @escaping () async throws -> Output
) -> AsyncPhase<Output, Error>

```
A hook to use the most recent phase of asynchronous operation of the passed function.
The function will be performed at the first update and will be re-performed according to the given updateStrategy.

```swift
let phase = useAsync(.once) {
  try await URLSession.shared.data(from: url)
}
```

### useAsyncPerform

```swift
func useAsyncPerform<Output>(
_ operation: @escaping @MainActor () async -> Output
) -> (phase: AsyncPhase<Output, Never>, perform: @MainActor () async -> Void)

func useAsyncPerform<Output>(
_ operation: @escaping @MainActor () async throws -> Output
) -> (phase: AsyncPhase<Output, Error>, perform: @MainActor () async -> Void)

```
A hook to use the most recent phase of the passed asynchronous operation, and a perform function to call the it at arbitrary timing.

```swift
let (phase, perform) = useAsyncPerform {
  try await URLSession.shared.data(from: url)
}

```

### usePublisher

```swift
func usePublisher<P: Publisher>(
_ updateStrategy: HookUpdateStrategy,
_ makePublisher: @escaping () -> P
) -> AsyncPhase<P.Output, P.Failure>

```
A hook to use the most recent phase of asynchronous operation of the passed publisher.
The publisher will be subscribed at the first update and will be re-subscribed according to the given updateStrategy.

```swift
let phase = usePublisher(.once) {
  URLSession.shared.dataTaskPublisher(for: url)
}
```

### usePublisherSubscribe

```swift
func usePublisherSubscribe<P: Publisher>(
_ makePublisher: @escaping () -> P
) -> (phase: AsyncPhase<P.Output, P.Failure>, subscribe: () -> Void)

```
A hook to use the most recent phase of asynchronous operation of the passed publisher, and a subscribe function to subscribe to it at arbitrary timing.

```swift
let (phase, subscribe) = usePublisherSubscribe {
  URLSession.shared.dataTaskPublisher(for: url)
}
```

### useEnvironment

```swift
func useEnvironment<Value>(_ keyPath: KeyPath<EnvironmentValues, Value>) -> Value
```

A hook to use environment value passed through the view tree without @Environment property wrapper.

```swift
let colorScheme = useEnvironment(\.colorScheme)  // ColorScheme

```

```swift
func useContext<T>(_ context: Context<T>.Type) -> T
```
A hook to use current context value that is provided by Context<T>.Provider.
The purpose is identical to use Context<T>.Consumer.
See Context section for more details.

```swift
let value = useContext(Context<Int>.self)  // Int
```
