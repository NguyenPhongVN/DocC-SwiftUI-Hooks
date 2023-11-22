import Hooks
import Foundation
import SwiftUI
import Combine

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
