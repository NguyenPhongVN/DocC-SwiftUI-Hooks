# RulesHooks

Hooks are Swift function programming, but you need to follow two rules when using them.

@Metadata {
  @PageImage(purpose: card, source: "gettingStarted-card", alt: "The profile images for a regular sloth and an ice sloth.")
}

## Overview

In order to take advantage of the wonderful interface of Hooks, the same rules that React hooks has must also be followed by SwiftUI Hooks.
Để tận dụng được interface tuyệt vời của Hooks, SwiftUI Hooks cũng phải tuân theo các rules tương tự mà React hooks đưa ra.

[Disclaimer]: Các quy tắc này không phải là các ràng buộc kỹ thuật dành riêng cho SwiftUI Hooks, nhưng cần thiết dựa trên thiết kế của Hooks.Bạn có thể xem tại đây (https://legacy.reactjs.org/docs/hooks-rules.html) để biết thêm về các quy tắc được xác định cho React Hooks.

* In -Onone builds, if a violation against this rules is detected, it asserts by an internal sanity check to help the developer notice the mistake in the use of hooks. However, hooks also has `disableHooksRulesAssertion` modifier in case you want to disable the assertions.

### Only Call Hooks at the Function Top Level

Không gọi Hooks bên trong điều kiện hoặc vòng lặp. Thứ tự hook được gọi rất quan trọng vì Hook sử dụng LinkedList (https://en.wikipedia.org/wiki/Linked_list) để theo dõi state của nó.

```swift
@ViewBuilder
func counterButton() -> some View {
  // 🟢 Uses hook at the top level
  @HState
  var count = 0

  Button("You clicked \(count) times") {
    count += 1
  }
}
```

```swift
@ViewBuilder
func counterButton() -> some View {
  if condition {
    // 🔴 Uses hook inside condition.
    @HState
    var count = 0

    Button("You clicked \(count.wrappedValue) times") {
      count.wrappedValue += 1
    }
  }
}
```

### Only Call Hooks from HookScope or HookView.hookBody

Để duy trì state, hook phải được gọi bên trong `HookScope`. view phù hợp với `HookView` protocol sẽ tự động được đặt trong `HookScope`.

```swift
struct CounterButton: HookView {  // 🟢 `HookView` is used.
  var hookBody: some View {

    @HState
    var count = 0

    Button("You clicked \(count.wrappedValue) times") {
      count.wrappedValue += 1
    }
  }
}

```

```swift
func counterButton() -> some View {
  HookScope {  // 🟢 `HookScope` is used.
    
    @HState
    var count = 0

    Button("You clicked \(count) times") {
      count += 1
    }
  }
}
```

```swift
struct ContentView: HookView {
  var hookBody: some View {
    counterButton()
  }

// 🟢 Called from `HookView.hookBody` or `HookScope`.
  @ViewBuilder
  var counterButton: some View {
    @HState
    var count = 0

    Button("You clicked \(count) times") {
      count += 1
    }
  }
}
```

```swift
// 🔴 Neither `HookScope` nor `HookView` is used, and is not called from them.
@ViewBuilder
func counterButton() -> some View {
  @HState
  var count = 0

  Button("You clicked \(count) times") {
    count += 1
  }
}
```
