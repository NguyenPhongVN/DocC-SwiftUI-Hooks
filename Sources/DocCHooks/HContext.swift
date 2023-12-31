import Foundation

// MARK: HContext

/// A @propertyWrapper for useContext/
///
///```swift
///
///      let todos = useContext(TodoContext.self)
///
///      @HContext
///      var todos = TodoContext.self
///```
///
///It's similar ``useContext(_:)``, but using propertyWrapper instead.

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
