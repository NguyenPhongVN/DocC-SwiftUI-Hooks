// The Swift Programming Language
// https://docs.swift.org/swift-book

@_exported import Hooks

import struct SwiftUI.Binding

extension Binding {
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


//import MWebSocket

//public extension MWebSocket {
//  
//  func toAsyncStream() -> AsyncStream<WebSocketEvent> {
//    AsyncStream { continuation in
//      let socket = socket
//      socket?.onEvent = { event in
//        continuation.yield(event)
//      }
//      continuation.onTermination = { @Sendable _ in
//        socket?.forceDisconnect()
//      }
//    }
//  }
//  
//  func toStringAsyncStream() -> AsyncStream<String> {
//    AsyncStream { continuation in
//      let socket = socket
//      socket?.onEvent = { event in
//        switch event {
//          case .text(let string):
//            continuation.yield(string)
//          case .binary(let data):
//            if let string = data.toString() {
//              continuation.yield(string)
//            }
//          default:
//            break
//        }
//      }
//      continuation.onTermination = { @Sendable _ in
//        socket?.forceDisconnect()
//      }
//    }
//  }
//  
//  func toDataAsyncStream() -> AsyncStream<Data> {
//    AsyncStream { continuation in
//      let socket = socket
//      socket?.onEvent = { event in
//        switch event {
//          case .text(let string):
//            if let data = string.toData() {
//              continuation.yield(data)
//            }
//          case .binary(let data):
//            continuation.yield(data)
//          default:
//            break
//        }
//      }
//      continuation.onTermination = { @Sendable _ in
//        socket?.forceDisconnect()
//      }
//    }
//  }
//}
//
//import CasePaths

//extension WebSocketEvent: Equatable {
//  public static func == (lhs: WebSocketEvent, rhs: WebSocketEvent) -> Bool {
//    switch (lhs, rhs) {
//      case (.connected, connected):
//        return (/WebSocketEvent.connected).extract(from: lhs) == (/WebSocketEvent.connected).extract(from: rhs)
//      case (.disconnected, .disconnected):
//        let rhsValue = (/WebSocketEvent.disconnected).extract(from: lhs)
//        let lhsValue = (/WebSocketEvent.disconnected).extract(from: rhs)
//        return (rhsValue?.0 == lhsValue?.0) && (rhsValue?.1 == lhsValue?.1)
//      case (.text, .text):
//        return (/WebSocketEvent.text).extract(from: lhs) == (/WebSocketEvent.text).extract(from: rhs)
//      case (.binary, .binary):
//        return (/WebSocketEvent.binary).extract(from: lhs) == (/WebSocketEvent.binary).extract(from: rhs)
//      case (.pong, .pong):
//        return (/WebSocketEvent.pong).extract(from: lhs) == (/WebSocketEvent.pong).extract(from: rhs)
//      case (.ping, .ping):
//        return (/WebSocketEvent.ping).extract(from: lhs) == (/WebSocketEvent.ping).extract(from: rhs)
//      case (.error, .error):
//        return areEqual((/WebSocketEvent.error).extract(from: lhs) as Any, (/WebSocketEvent.error).extract(from: rhs)! as Any)
//      case (.viabilityChanged, .viabilityChanged):
//        return (/WebSocketEvent.viabilityChanged).extract(from: lhs) == (/WebSocketEvent.viabilityChanged).extract(from: rhs)
//      case (.reconnectSuggested, .reconnectSuggested):
//        return (/WebSocketEvent.reconnectSuggested).extract(from: lhs) == (/WebSocketEvent.reconnectSuggested).extract(from: rhs)
//      case (.cancelled, .cancelled):
//        return true
//      default:
//        return false
//    }
//  }
//}

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

import Foundation

// MARK: Dictionary
internal extension Dictionary {
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
internal extension Encodable {
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
internal extension Data {
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
internal extension String {
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

//import RealmSwift
//import IdentifiedCollections
//
//public extension Realm.Configuration {
//  /// Description
//  /// - Returns: Configuration
//  static func config() -> Realm.Configuration {
//    var config = Realm.Configuration()
//    config.fileURL = config.fileURL!.deletingLastPathComponent().appendingPathComponent("app.realm")
//    config.schemaVersion = 5
//    config.migrationBlock = { migration, oldSchemaVersion in
//      if oldSchemaVersion < 5 {
//        config.deleteRealmIfMigrationNeeded = true
//        //        Realm.deleteRealmFile()
//      }
//    }
//    Realm.Configuration.defaultConfiguration = config
//    //    Realm.deleteRealmFile()
//    return config
//  }
//}
//
//public extension Realm {
//  /// instance Realm
//  static let instance: Realm = try! Realm(configuration: Realm.Configuration.config())
//}
//
//public extension Realm {
//  static func deleteRealmFile() {
//    let url = Realm.Configuration.defaultConfiguration.fileURL!
//    remove(realmURL: url)
//  }
//  
//  static func remove(realmURL: URL) {
//    let realmURLs = [
//      realmURL,
//      realmURL.appendingPathExtension("lock"),
//      realmURL.appendingPathExtension("note"),
//      realmURL.appendingPathExtension("management"),
//    ]
//    for URL in realmURLs {
//      try? FileManager.default.removeItem(at: URL)
//    }
//  }
//}
//
//public extension Array where Element: Identifiable {
//  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
//    var identifiedArray: IdentifiedArrayOf<Element> = []
//    for value in self {
//      identifiedArray.updateOrAppend(value)
//    }
//    return identifiedArray
//  }
//}
//
//public extension IdentifiedArray {
//  func toArray() -> [Element] {
//    var array: [Element] = []
//    for value in self {
//      array.append(value)
//    }
//    return array
//  }
//}
//
//public extension IdentifiedArray where Element: Identifiable {
//  
//  @discardableResult
//  mutating func updateOrAppend(_ other: Self) -> Self {
//    for item in other {
//      self.updateOrAppend(item)
//    }
//    return self
//  }
//  
//  @discardableResult
//  mutating func updateOrAppend(_ other: [Element]) -> Self {
//    for item in other {
//      self.updateOrAppend(item)
//    }
//    return self
//  }
//  
//  @discardableResult
//  mutating func updateOrAppend(ifLet item: Element?) -> Self {
//    guard let item = item else {
//      return self
//    }
//    self.updateOrAppend(item)
//    return self
//  }
//}
//
//
//// MARK: - Realm Collection Transform to Array
//public extension List {
//  func toArray() -> Array<Element> {
//    Array(self)
//  }
//}
//
//public extension Results {
//  func toArray() -> Array<Element> {
//    Array(self)
//  }
//}
//
//public extension LinkingObjects {
//  func toArray() -> Array<Element> {
//    Array(self)
//  }
//}
//
//// MARK: - Realm Collection Transform to IdentifiedArray
//public extension List where Element: Identifiable {
//  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
//    toArray().toIdentifiedArray()
//  }
//}
//
//public extension Results where Element: Identifiable {
//  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
//    toArray().toIdentifiedArray()
//  }
//}
//
//public extension LinkingObjects where Element: Identifiable {
//  func toIdentifiedArray() -> IdentifiedArrayOf<Element> {
//    toArray().toIdentifiedArray()
//  }
//}
//
//// MARK: - Array to Realm Collection
//public extension Array where Element: RealmCollectionValue {
//  func toList() -> List<Element> {
//    let list: List<Element> = .init()
//    list.append(objectsIn: self)
//    return list
//  }
//}
//
//// MARK: - IdentifiedArray to Realm Collection
//public extension IdentifiedArrayOf where Element: RealmCollectionValue {
//  func toList() -> List<Element> {
//    toArray().toList()
//  }
//}
//
////import MCombineRequest
//
//public func usePublisherRequest<R: MRequest>(
//  _ updateStrategy: HookUpdateStrategy = .once,
//  _ request: R
//) -> AsyncPhase<R.Output, any Error> {
//  usePublisherRequest(updateStrategy, { request })
//}
//
//public func usePublisherRequest<R: MRequest>(
//  _ updateStrategy: HookUpdateStrategy = .once,
//  _ request: @escaping () -> R
//) -> AsyncPhase<R.Output, any Error> {
//  usePublisher(updateStrategy, request)
//    .mapError {
//      $0 as (any Error)
//    }
//}
//
//public func useAsyncRequest<R: MRequest>(
//  _ updateStrategy: HookUpdateStrategy = .once,
//  _ request: R
//) -> AsyncPhase<Data, any Error> {
//  useAsyncRequest(updateStrategy, { request })
//}
//
//public func useAsyncRequest<R: MRequest>(
//  _ updateStrategy: HookUpdateStrategy = .once,
//  _ request: @escaping () -> R
//) -> AsyncPhase<Data, any Error> {
//  useAsync<Data>(updateStrategy) {
//    try await request().data
//  }
//  .mapError {
//    $0 as (any Error)
//  }
//}
//
//public func usePublisherRequestRefresh<R: MRequest>(
//  _ request: R
//) -> (AsyncPhase<R.Output, any Error>, refresher: () -> Void) {
//  let (phase, refresh) = usePublisherSubscribe { request }
//  return (phase.mapError { $0 as (any Error)}, refresh)
//}
//
//public func usePublisherRequestRefresh<R: MRequest>(
//  _ request: @escaping () -> R
//) -> (AsyncPhase<R.Output, any Error>, refresher: () -> Void) {
//  let (phase, refresh) = usePublisherSubscribe(request)
//  return (phase.mapError { $0 as (any Error)}, refresh)
//}
//
//public func useRequest(
//  _ updateStrategy: HookUpdateStrategy = .once,
//  @RequestBuilder builder: () -> any RequestProtocol
//) -> AsyncPhase<Data, any Error> {
//  useAsyncRequest(
//    updateStrategy,
//    MRequest(builder: builder)
//  )
//}
//
//public func useRequestRefresh(
//  @RequestBuilder builder: @escaping () -> any RequestProtocol
//) -> (AsyncPhase<Data, any Error>, @MainActor () async -> Void) {
//  let (phase, refresh) = useAsyncPerform {
//    try await MRequest(builder: builder).data
//  }
//  return (phase.mapError { $0 as (any Error)}, refresh)
//}
//
//public func useAddDatabase<O: RealmSwift.Object>(_ object: O) {
//  let realm = Realm.instance
//  try? realm.write {
//    realm.add(object, update: .all)
//  }
//}
//
//public func useUpdateDatabase<O: RealmSwift.Object>(_ object: O) where O: Identifiable {
//  let realm = Realm.instance
//  try? realm.write {
//    realm.add(object, update: .all)
//  }
//}
//
//public func usePublisherPhaseDatabase<O: RealmSwift.Object>(
//  _ object: O.Type
//) -> AsyncPhase<Results<O>, any Error> {
//  return usePublisher(.once) {
//    let realm = Realm.instance
//    return realm.objects(object).collectionPublisher
//  }
//}
//
//public func useAsyncPhaseDatabase<O: RealmSwift.Object>(
//  _ object: O.Type
//) -> AsyncPhase<Results<O>, any Error> {
//  useAsync(.once) {
//    let realm = Realm.instance
//    let items = try await realm.objects(object).subscribe(waitForSync: .always)
//    return items
//  }
//}
//
//public func useObjectDatabase<O: RealmSwift.Object>(
//  _ object: O.Type
//) -> Results<O> {
//  let realm = Realm.instance
//  return realm.objects(object)
//}
//
//public func useDeleteDatabase<O: RealmSwift.Object>(
//  _ object: O.Type
//) {
//  let realm = Realm.instance
//  let items = realm.objects(object)
//  try! realm.write {
//    for item in items {
//      realm.delete(item)
//    }
//  }
//}
//
//public func useDeleteDatabase<O: RealmSwift.Object>(
//  _ object: O.Type,
//  _ id: O.ID
//) where O: Identifiable {
//  let realm = Realm.instance
//  if let item = realm.object(ofType: object, forPrimaryKey: id) {
//    try! realm.write {
//      realm.delete(item)
//    }
//  }
//}
