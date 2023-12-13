import Hooks
import Foundation
import SwiftUI
import Combine

/// Watches a value and triggers a callback whenever the value changed.

/// `useValueChanged` takes a valueChange callback and calls it whenever value changed. valueChange will not be called on the first useValueChanged call.

///`useValueChanged` can also be used to interpolate Whenever useValueChanged is called with a different value, calls valueChange. The value returned by useValueChanged is the latest returned value of valueChange or null.

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

public func useNextPhaseValue<Success, Failure>(
  _ phase: AsyncPhase<Success, Failure>
) -> Success? {
  @HRef
  var ref = phase.value
  useLayoutEffect {
    if let value = phase.value {
      ref = value
    }
    return nil
  }
  return ref
}

public func useCount(
  _ updateStrategy: HookUpdateStrategy = .once
) -> Int {
  @HState var count = 0
  useMemo(updateStrategy) {
    count += 1
  }
  return count
}

/// Description
/// - Returns: Date
public func useDate() -> Date? {
  let phase = usePublisher(.once) {
    Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .prepend(Date())
  }
  return phase.value
}

/// Description
/// - Parameter date: date description
/// - Returns: Date
public func useDate(date: Date) -> Date? {
  let phase = usePublisher(.once) {
    Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .prepend(date)
  }
  return phase.value
}

/// Description
/// - Returns: AsyncPhase
public func usePhaseDate() -> AsyncPhase<Date, Never> {
  usePublisher(.once) {
    Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .prepend(Date())
  }
}

/// Description
/// - Returns: AsyncPhase
public func usePhaseDate(date: Date) -> AsyncPhase<Date, Never> {
  usePublisher(.once) {
    Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .prepend(date)
  }
}

public func useCountdown(
  countdown: Double,
  withTimeInterval: TimeInterval = 0.1
) -> HookCountdownState {
  
  @HState
  var count = countdown
  
  @HState
  var isAutoCountdown = false
  
  @HState
  var phase = HookCountdownState.CountdownPhase.pending
  
  useEffect(.preserved(by: isAutoCountdown)) {
    guard isAutoCountdown else { return nil }
    let timer = Timer.scheduledTimer(withTimeInterval: withTimeInterval, repeats: true) { _ in
      if count <= 0 {
        phase = .completion
        isAutoCountdown = false
      } else {
        count -= withTimeInterval
        phase = .process(count)
      }
    }
    return timer.invalidate
  }
  
  return HookCountdownState(
    value: $count,
    isAutoCountdown: $isAutoCountdown,
    start: {
      phase = .start(countdown)
      count = countdown
      isAutoCountdown = true
    },
    stop: {
      phase = .stop
      isAutoCountdown = false
    },
    play: {
      isAutoCountdown = true
    },
    cancel: {
      phase = .cancel
      count = countdown
      isAutoCountdown = false
    },
    phase: $phase
  )
}

public struct HookCountdownState {
  public let value: Binding<Double>
  public let isAutoCountdown: Binding<Bool>
  public var start: () -> ()
  public var stop: () -> ()
  public var play: () -> ()
  public var cancel: () -> ()
  public var phase: Binding<CountdownPhase>
}

extension HookCountdownState {
  public enum CountdownPhase: Equatable {
    case pending
    case start(Double)
    case stop
    case cancel
    case process(Double)
    case completion
  }
}

@propertyWrapper
public struct HCountdown {
  
  public var wrappedValue: Double
  
  public var withTimeInterval: Double
  
  public init(wrappedValue: Double, withTimeInterval: Double) {
    self.wrappedValue = wrappedValue
    self.withTimeInterval = withTimeInterval
  }
  
  public var projectedValue: Self {
    self
  }
  
  public var value: HookCountdownState {
    useCountdown(countdown: wrappedValue, withTimeInterval: withTimeInterval)
  }
}

// MARK: Call operation only `updateStrategy` changes, It will updateUI status AsyncPhase.

/// A hook to use the most recent phase of asynchronous operation of the passed non-throwing function.
/// The function will be performed at the first update and will be re-performed according to the given `updateStrategy`.
///
///     let phase = useAsyncSequence(.once) {
///
///     }
///
/// - Parameters:
///   - updateStrategy: A strategy that determines when to re-perform the given function.
///   - operation: A closure that produces a resulting value asynchronously.
/// - Returns: A most recent async phase.
@discardableResult
public func useAsyncSequence<Output>(
  _ updateStrategy: HookUpdateStrategy? = .once,
  _ operation: AsyncStream<Output>
) -> AsyncPhase<Output, Never> {
  useHook(
    AsyncSequenceHook(
      updateStrategy: updateStrategy,
      operation: operation
    )
  )
}

// MARK: Call operation only `updateStrategy` changes, It will updateUI status AsyncPhase.

/// A hook to use the most recent phase of asynchronous operation of the passed non-throwing function.
/// The function will be performed at the first update and will be re-performed according to the given `updateStrategy`.
///
///     let phase = useAsyncSequence(.once) {
///
///     }
///
/// - Parameters:
///   - updateStrategy: A strategy that determines when to re-perform the given function.
///   - operation: A closure that produces a resulting value asynchronously.
/// - Returns: A most recent async phase.
@discardableResult
public func useAsyncSequence<Output>(
  _ updateStrategy: HookUpdateStrategy? = .once,
  _ operation: () -> AsyncStream<Output>
) -> AsyncPhase<Output, Never> {
  useHook(
    AsyncSequenceHook(
      updateStrategy: updateStrategy,
      operation: operation()
    )
  )
}

/// A hook to use the most recent phase of asynchronous operation of the passed throwing function.
/// The function will be performed at the first update and will be re-performed according to the given `updateStrategy`.
///
///     let phase = useAsync(.once) {
///
///     }
///
/// - Parameters:
///   - updateStrategy: A strategy that determines when to re-perform the given function.
///   - operation: A closure that produces a resulting value asynchronously.
/// - Returns: A most recent async phase.
@discardableResult
public func useAsyncThrowingSequence<Output>(
  _ updateStrategy: HookUpdateStrategy? = .once,
  _ operation: AsyncThrowingStream<Output, any Error>
) -> AsyncPhase<Output, any Error> {
  useHook(
    AsyncThrowingSequenceHook(
      updateStrategy: updateStrategy,
      operation: operation
    )
  )
}

/// A hook to use the most recent phase of asynchronous operation of the passed throwing function.
/// The function will be performed at the first update and will be re-performed according to the given `updateStrategy`.
///
///     let phase = useAsync(.once) {
///
///     }
///
/// - Parameters:
///   - updateStrategy: A strategy that determines when to re-perform the given function.
///   - operation: A closure that produces a resulting value asynchronously.
/// - Returns: A most recent async phase.
@discardableResult
public func useAsyncThrowingSequence<Output>(
  _ updateStrategy: HookUpdateStrategy? = .once,
  _ operation: () -> AsyncThrowingStream<Output, any Error>
) -> AsyncPhase<Output, any Error> {
  useHook(
    AsyncThrowingSequenceHook(
      updateStrategy: updateStrategy,
      operation: operation()
    )
  )
}

private struct AsyncSequenceHook<Output>: Hook {
  
  typealias State = _HookRef
  
  typealias Value = AsyncPhase<Output, Never>
  
  let updateStrategy: HookUpdateStrategy?
  
  let operation: AsyncStream<Output>
  
  init(
    updateStrategy: HookUpdateStrategy?,
    operation: AsyncStream<Output>
  ) {
    self.updateStrategy = updateStrategy
    self.operation = operation
  }
  
  func makeState() -> State {
    State(operation: operation)
  }
  
  func value(coordinator: Coordinator) -> Value {
    coordinator.state.phase
  }
  
  func updateState(coordinator: Coordinator) {
    guard !coordinator.state.isDisposed else {
      return
    }
    let sequence = coordinator.state.operation
    coordinator.state.task = Task { @MainActor in
      for await element in sequence {
        if !Task.isCancelled && !coordinator.state.isDisposed {
          coordinator.state.phase = .success(element)
          coordinator.updateView()
        }
      }
    }
  }
  
  func dispose(state: State) {
    state.dispose()
  }
}

private extension AsyncSequenceHook {
  // MARK: State
  final class _HookRef {
    
    var phase: Value = .pending
    
    let operation: AsyncStream<Output>
    
    var task: Task<Void, Never>? {
      didSet {
        oldValue?.cancel()
      }
    }
    
    init(operation: AsyncStream<Output>) {
      self.operation = operation
    }
    
    var isDisposed = false
    
    func dispose() {
      task = nil
      isDisposed = true
    }
  }
}

private struct AsyncThrowingSequenceHook<Output>: Hook {
  
  typealias State = _HookRef
  
  typealias Value = AsyncPhase<Output, any Error>
  
  let updateStrategy: HookUpdateStrategy?
  
  let operation: AsyncThrowingStream<Output, any Error>
  
  init(
    updateStrategy: HookUpdateStrategy?,
    operation: AsyncThrowingStream<Output, any Error>
  ) {
    self.updateStrategy = updateStrategy
    self.operation = operation
  }
  
  func makeState() -> State {
    State(operation: operation)
  }
  
  func value(coordinator: Coordinator) -> Value {
    coordinator.state.phase
  }
  
  func updateState(coordinator: Coordinator) {
    guard !coordinator.state.isDisposed else {
      return
    }
    let sequence = coordinator.state.operation
    coordinator.state.task = Task { @MainActor in
      do {
        for try await element in sequence {
          if !Task.isCancelled && !coordinator.state.isDisposed {
            coordinator.state.phase = .success(element)
            coordinator.updateView()
          }
        }
      } catch {
        if !Task.isCancelled && !coordinator.state.isDisposed {
          coordinator.state.phase = .failure(error)
          coordinator.updateView()
        }
      }
    }
  }
  
  func dispose(state: State) {
    state.dispose()
  }
}

private extension AsyncThrowingSequenceHook {
  // MARK: State
  final class _HookRef {
    
    var phase: Value = .pending
    
    let operation: AsyncThrowingStream<Output, any Error>
    
    var task: Task<Void, Never>? {
      didSet {
        oldValue?.cancel()
      }
    }
    
    init(operation: AsyncThrowingStream<Output, any Error>) {
      self.operation = operation
    }
    
    var isDisposed = false
    
    func dispose() {
      task = nil
      isDisposed = true
    }
  }
}
