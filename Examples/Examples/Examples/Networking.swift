import MCombineRequest
import Foundation

public func usePublisherRequest<R: MRequest>(
  _ updateStrategy: HookUpdateStrategy = .once,
  _ request: R
) -> AsyncPhase<R.Output, R.Failure> {
  usePublisherRequest(updateStrategy, { request })
}

public func usePublisherRequest<R: MRequest>(
  _ updateStrategy: HookUpdateStrategy = .once,
  _ request: @escaping () -> R
) -> AsyncPhase<R.Output, R.Failure> {
  usePublisher(updateStrategy, request)
}

public func useAsyncRequest<R: MRequest>(
  _ updateStrategy: HookUpdateStrategy = .once,
  _ request: R
) -> AsyncPhase<Data, any Error> {
  useAsyncRequest(updateStrategy, { request })
}

public func useAsyncRequest<R: MRequest>(
  _ updateStrategy: HookUpdateStrategy = .once,
  _ request: @escaping () -> R
) -> AsyncPhase<Data, any Error> {
  useAsync<Data>(updateStrategy) {
    try await request().data
  }
  .mapError {
    $0 as (any Error)
  }
}

public func usePublisherRequestRefresh<R: MRequest>(
  _ request: R
) -> (AsyncPhase<R.Output, R.Failure>, refresher: () -> Void) {
  let (phase, refresh) = usePublisherSubscribe { request }
  return (phase, refresh)
}

public func usePublisherRequestRefresh<R: MRequest>(
  _ request: @escaping () -> R
) -> (AsyncPhase<R.Output, R.Failure>, refresher: () -> Void) {
  let (phase, refresh) = usePublisherSubscribe(request)
  return (phase, refresh)
}

public func useRequest(
  _ updateStrategy: HookUpdateStrategy = .once,
  @RequestBuilder builder: () -> any RequestProtocol
) -> AsyncPhase<Data, any Error> {
  useAsyncRequest(
    updateStrategy,
    MRequest(builder: builder)
  )
}

public func useRequestRefresh(
  @RequestBuilder builder: @escaping () -> any RequestProtocol
) -> (AsyncPhase<Data, any Error>, @MainActor () async -> Void) {
  let (phase, refresh) = useAsyncPerform {
    try await MRequest(builder: builder).data
  }
  return (phase.mapError { $0 as (any Error)}, refresh)
}

import MWebSocket

public extension MWebSocket {

  func toAsyncStream() -> AsyncStream<WebSocketEvent> {
    AsyncStream { continuation in
      let socket = socket
      socket?.onEvent = { event in
        continuation.yield(event)
      }
      continuation.onTermination = { @Sendable _ in
        socket?.forceDisconnect()
      }
    }
  }

  func toStringAsyncStream() -> AsyncStream<String> {
    AsyncStream { continuation in
      let socket = socket
      socket?.onEvent = { event in
        switch event {
          case .text(let string):
            continuation.yield(string)
          case .binary(let data):
            if let string = data.toString() {
              continuation.yield(string)
            }
          default:
            break
        }
      }
      continuation.onTermination = { @Sendable _ in
        socket?.forceDisconnect()
      }
    }
  }

  func toDataAsyncStream() -> AsyncStream<Data> {
    AsyncStream { continuation in
      let socket = socket
      socket?.onEvent = { event in
        switch event {
          case .text(let string):
            if let data = string.toData() {
              continuation.yield(data)
            }
          case .binary(let data):
            continuation.yield(data)
          default:
            break
        }
      }
      continuation.onTermination = { @Sendable _ in
        socket?.forceDisconnect()
      }
    }
  }
}

import CasePaths

extension WebSocketEvent: Equatable {
  public static func == (lhs: WebSocketEvent, rhs: WebSocketEvent) -> Bool {
    switch (lhs, rhs) {
      case (.connected, connected):
        return (/WebSocketEvent.connected).extract(from: lhs) == (/WebSocketEvent.connected).extract(from: rhs)
      case (.disconnected, .disconnected):
        let rhsValue = (/WebSocketEvent.disconnected).extract(from: lhs)
        let lhsValue = (/WebSocketEvent.disconnected).extract(from: rhs)
        return (rhsValue?.0 == lhsValue?.0) && (rhsValue?.1 == lhsValue?.1)
      case (.text, .text):
        return (/WebSocketEvent.text).extract(from: lhs) == (/WebSocketEvent.text).extract(from: rhs)
      case (.binary, .binary):
        return (/WebSocketEvent.binary).extract(from: lhs) == (/WebSocketEvent.binary).extract(from: rhs)
      case (.pong, .pong):
        return (/WebSocketEvent.pong).extract(from: lhs) == (/WebSocketEvent.pong).extract(from: rhs)
      case (.ping, .ping):
        return (/WebSocketEvent.ping).extract(from: lhs) == (/WebSocketEvent.ping).extract(from: rhs)
      case (.error, .error):
        return areEqual((/WebSocketEvent.error).extract(from: lhs) as Any, (/WebSocketEvent.error).extract(from: rhs)! as Any)
      case (.viabilityChanged, .viabilityChanged):
        return (/WebSocketEvent.viabilityChanged).extract(from: lhs) == (/WebSocketEvent.viabilityChanged).extract(from: rhs)
      case (.reconnectSuggested, .reconnectSuggested):
        return (/WebSocketEvent.reconnectSuggested).extract(from: lhs) == (/WebSocketEvent.reconnectSuggested).extract(from: rhs)
      case (.cancelled, .cancelled):
        return true
      default:
        return false
    }
  }
}

fileprivate func areEqual(_ lhs: Any,_ rhs: Any) -> Bool {
  guard
    let lhs = lhs as? any Equatable,
    let rhs = rhs as? any Equatable
  else { return false }
  
  return lhs.isEqual(rhs)
}

fileprivate extension Equatable {
  func isEqual(_ other: any Equatable) -> Bool {
    guard let other = other as? Self else {
      return other.isExactlyEqual(self)
    }
    return self == other
  }
  
  func isExactlyEqual(_ other: any Equatable) -> Bool {
    guard let other = other as? Self else {
      return false
    }
    return self == other
  }
}
