// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported import Hooks

import struct SwiftUI.Binding

public extension Binding {
  func map<NewValue>(
    _ keyPath: WritableKeyPath<Value, NewValue>
  ) -> Binding<NewValue> {
    Binding<NewValue>(
      get: { wrappedValue[keyPath: keyPath] },
      set: { wrappedValue[keyPath: keyPath] = $0 }
    )
    .transaction(transaction)
  }
}

// MARK: Task sleep
extension Task where Success == Never, Failure == Never {
  /// Suspends the current task for at least the given duration
  /// in nanoseconds.
  ///
  /// If the task is canceled before the time ends,
  /// this function throws `CancellationError`.
  ///
  /// This function doesn't block the underlying thread.
  public static func sleep(seconds: Double) async throws {
    let duration = UInt64(seconds*1_000_000_000)
    try await Task.sleep(nanoseconds: duration)
  }
}

typealias HookContext = Hooks.Context

extension AsyncPhase {
  /// The status using in HookUpdateStrategy to order handle response phase.
  public enum StatusPhase: Hashable, Equatable {
    /// Represents a pending phase meaning that the operation has not been started.
    case pending
    
    /// Represents a running phase meaning that the operation has been started, but has not yet provided a result.
    case running
    
    /// Represents a success phase meaning that the operation provided a value with success.
    case success
    
    /// Represents a failure phase meaning that the operation provided an error with failure.
    case failure
  }
  
  /// the status of phase which we can compare to update HookUpdateStrategy.
  public var status: StatusPhase {
    switch self {
      case .pending:
        return .pending
      case .running:
        return .running
      case .success(_):
        return .success
      case .failure(_):
        return .failure
    }
  }
  
  /// A boolean value indicating whether `self` is ``AsyncPhase/pending`` or ``AsyncPhase/running``.
  public var isLoading: Bool {
    switch self.status {
      case .pending, .running:
        return true
      case .success, .failure:
        return false
    }
  }
  
  /// A boolean value indicating whether `self` is ``AsyncPhase/success(_:)`` or ``AsyncPhase/failure(_:)``.
  public var hasResponded: Bool {
    switch self.status {
      case .pending, .running:
        return false
      case .success, .failure:
        return true
    }
  }
}

/// A hook to use the most recent phase of the passed non-throwing asynchronous operation, and a `perform` function to call the it at arbitrary timing.
///
///     let (phase, perform) = useAsyncPerform {
///         try! await URLSession.shared.data(from: url)
///     }
///
/// - Parameter operation: A closure that produces a resulting value asynchronously.
/// - Returns: A tuple of the most recent async phase and its perform function.
@discardableResult
public func useAsyncRefresh<Output>(
  _ operation: @escaping @MainActor () async -> Output
) -> (
  phase: AsyncPhase<Output, Never>,
  refresh: @MainActor () async -> Void
) {
  useHook(AsyncRefreshHook(operation: operation))
}

/// A hook to use the most recent phase of the passed throwing asynchronous operation, and a `perform` function to call the it at arbitrary timing.
///
///     let (phase, perform) = useAsyncPerform {
///         try await URLSession.shared.data(from: url)
///     }
///
/// - Parameter operation: A closure that produces a resulting value asynchronously.
/// - Returns: A most recent async phase.
@discardableResult
public func useAsyncRefresh<Output>(
  _ operation: @escaping @MainActor () async throws -> Output
) -> (
  phase: AsyncPhase<Output, Error>,
  refresh: @MainActor () async -> Void
) {
  useHook(AsyncThrowingRefreshHook(operation: operation))
}

internal struct AsyncRefreshHook<Output>: Hook {
  let updateStrategy: HookUpdateStrategy? = .once
  let operation: @MainActor () async -> Output
  
  func makeState() -> State {
    State()
  }
  
  func value(coordinator: Coordinator) -> (
    phase: AsyncPhase<Output, Never>,
    refresh: @MainActor () async -> Void
  ) {
    (
      phase: coordinator.state.phase,
      refresh: {
        guard !coordinator.state.isDisposed else {
          return
        }
        
//        coordinator.state.phase = .running
//        coordinator.updateView()
//        
        let output = await operation()
        
        if !Task.isCancelled {
          coordinator.state.phase = .success(output)
          coordinator.updateView()
        }
      }
    )
  }
  
  func dispose(state: State) {
    state.isDisposed = true
  }
}

internal extension AsyncRefreshHook {
  final class State {
    var phase = AsyncPhase<Output, Never>.pending
    var isDisposed = false
  }
}

internal struct AsyncThrowingRefreshHook<Output>: Hook {
  let updateStrategy: HookUpdateStrategy? = .once
  let operation: @MainActor () async throws -> Output
  
  func makeState() -> State {
    State()
  }
  
  func value(coordinator: Coordinator) -> (
    phase: AsyncPhase<Output, Error>,
    refresh: @MainActor () async -> Void
  ) {
    (
      phase: coordinator.state.phase,
      refresh: {
        guard !coordinator.state.isDisposed else {
          return
        }
        
//        coordinator.state.phase = .running
//        coordinator.updateView()
        
        let phase: AsyncPhase<Output, Error>
        
        do {
          let output = try await operation()
          phase = .success(output)
        }
        catch {
          phase = .failure(error)
        }
        
        if !Task.isCancelled {
          coordinator.state.phase = phase
          coordinator.updateView()
        }
      }
    )
  }
  
  func dispose(state: State) {
    state.isDisposed = true
  }
}

internal extension AsyncThrowingRefreshHook {
  final class State {
    var phase = AsyncPhase<Output, Error>.pending
    var isDisposed = false
  }
}

import Foundation

// MARK: Dictionary
public extension Dictionary {
  func toData() -> Data? {
    do {
      return try JSONSerialization.data(withJSONObject: self, options: [])
    } catch {
      return nil
    }
  }
  
  func toModel<D>(_ type: D.Type, using decoder: JSONDecoder? = nil) -> D? where D : Decodable {
    toData()?.toModel(type, using: decoder)
  }
  
  func toString(using: String.Encoding = .utf8) -> String? {
    guard let data = self.toData() else {return nil}
    return String(data: data, encoding: using)
  }
}

// MARK: Encodable
public extension Encodable {
  func toData(using encoder: JSONEncoder? = nil) -> Data? {
    let encoder = encoder ?? JSONEncoder()
    return try? encoder.encode(self)
  }
  
  func toDictionary(using encoder: JSONEncoder? = nil) -> [String: Any]? {
    toData(using: encoder)?.toDictionary()
  }
  
  func toModel<D>(_ type: D.Type, using encoder: JSONEncoder? = nil) -> D? where D: Decodable {
    toData(using: encoder)?.toModel(type)
  }
}

// MARK: Data
public extension Data {
  func toString(encoding: String.Encoding = .utf8) -> String? {
    String(data: self, encoding: encoding)
  }
  
  func toModel<D>(_ type: D.Type, using decoder: JSONDecoder? = nil) -> D? where D: Decodable {
    let decoder = decoder ?? JSONDecoder()
    return try? decoder.decode(type, from: self)
  }
  
  func toDictionary() -> [String: Any]? {
    do {
      let json = try JSONSerialization.jsonObject(with: self)
      return json as? [String: Any]
    } catch {
      return nil
    }
  }
  
#if os(iOS)
  func toData(keyPath: String? = nil) -> Self {
    guard let keyPath = keyPath else {
      return self
    }
    do {
      let json = try JSONSerialization.jsonObject(with: self, options: [])
      if let nestedJson = (json as AnyObject).value(forKeyPath: keyPath) {
        guard JSONSerialization.isValidJSONObject(nestedJson) else {
          return self
        }
        let data = try JSONSerialization.data(withJSONObject: nestedJson)
        return data
      }
    } catch {
      return self
    }
    return self
  }
#endif
}

// MARK: String
public extension String {
  func toData(using:String.Encoding = .utf8) -> Data? {
    return self.data(using: using)
  }
  
  func toModel<D>(_ type: D.Type, using decoder: JSONDecoder? = nil) -> D? where D : Decodable {
    return self.toData()?.toModel(type,using: decoder)
  }
  
  func toDictionary() -> [String: Any]? {
    guard let data = self.toData() else {return nil}
    do {
      return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    } catch {
      return nil
    }
  }
}

