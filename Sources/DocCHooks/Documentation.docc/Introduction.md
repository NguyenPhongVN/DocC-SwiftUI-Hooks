# Introduction

A SwiftUI implementation of React Hooks. Enhances reusability of stateful logic and gives state and lifecycle to function view.

@Metadata {
  @PageImage(purpose: card, source: "gettingStarted-card", alt: "The profile images for a regular sloth and an ice sloth.")
}

## Overview

SwiftUI Hooks là một phiên bản được dịch ra của React Hooks, hắn đưa State và lifecycle vào trong View mà không phụ thuộc vào các Element chỉ được phép sử dụng trong struct View  như @State hoặc @ObservedObject.
Nó cho phép bạn sử dụng lại logic trạng thái giữa các View bằng cách xây dựng các hook (móc) tùy chỉnh được tạo bằng nhiều hook (móc).
Hơn nữa, các hook như useEffect cũng giải quyết được vấn đề thiếu vòng đời trong SwiftUI.

API và behavioral specs (thông số kỹ thuật hành vi) của SwiftUI Hook hoàn toàn dựa trên React Hook, vì vậy bạn có thể tận dụng kiến thức về ứng dụng web để làm lợi thế cho mình.

### Examples

Basic Hooks

```swift

func timer() -> some View {
  HookScope {

    let time = useState(Date())

    useEffect(.once) {
      let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {
        time.wrappedValue = $0.fireDate
      }

      return {
        timer.invalidate()
      }
    }

    return Text("Time: \(time.wrappedValue)")
  }
}
```

```swift
var contentOther: some View {
  HookScope {

    let state = useState(0)

    let otherState = useState {
      0
    }

    let toggle = useState(false)

    let _ = useLogger(nil, toggle.wrappedValue)

    let _ = useLogger(.preserved(by: toggle.wrappedValue), toggle.wrappedValue)

    VStack {
      Stepper(value: state) {
        Text(state.wrappedValue.description)
      }

      Stepper(value: otherState) {
        Text(otherState.wrappedValue.description)
      }

      Toggle("", isOn: toggle)
        .toggleStyle(.switch)
    }
  }
}

```

Advance Hooks

```swift

var content: some View {
  HookScope {

    @HState var state = 0

    @HState<Int> var otherState = {
      0
    }

    @HState var toggle = false

    @HLogger
    var log = toggle

    @HLogger(.preserved(by: toggle))
    var otherLog = toggle

    VStack {
      Stepper(value: $state) {
        Text(state.description)
      }

      Stepper(value: $otherState) {
        Text(otherState.description)
      }

      Toggle("", isOn: $toggle)
        .toggleStyle(.switch)
      }
  }
}

```
