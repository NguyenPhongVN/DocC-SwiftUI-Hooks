import Foundation
import Hooks

open class RefBase {}

open class AnyRef<Value>: RefBase {
  
  private var _value: RefObject<Value>
  
  public init(value: Value) {
    self._value = RefObject(value)
  }
  
  open var value: Value {
    get {
      _value.current
    }
    set {
      _value.current = newValue
    }
  }
  
  open func send(_ value: Value) {
    self.value = value
  }
}

@dynamicMemberLookup
@propertyWrapper
public struct SAnyRef<Node> {
  
  internal let _value: AnyRef<Node>
  
  public init(wrappedValue: @escaping () -> Node) {
    _value = .init(value: wrappedValue())
  }
  
  public init(wrappedValue: Node) {
    _value = .init(value: wrappedValue)
  }
  
  public var wrappedValue: Node {
    get {
      _value.value
    }
    nonmutating set {
      _value.value = newValue
    }
  }
  
  public var projectedValue: Self {
    self
  }
  
  public var value: Node {
    get {
      _value.value
    }
    nonmutating set {
      _value.value = newValue
    }
  }
  
  public subscript<Value: Equatable>(
    dynamicMember keyPath: WritableKeyPath<Node, Value>
  ) -> Value {
    get {
      _value.value[keyPath: keyPath]
    }
    set {
      _value.value[keyPath: keyPath] = newValue
    }
  }
}

