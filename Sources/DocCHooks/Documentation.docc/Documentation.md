# ``DocCHooks``

A SwiftUI implementation of React Hooks. Enhances reusability of stateful logic and gives state and lifecycle to function view.

@Metadata {¡
  @PageImage(
             purpose: icon, 
             source: "slothCreator-icon", 
             alt: "A technology icon representing the SlothCreator framework.")
  @PageColor(green)
}

@Options(scope: global) {
  @AutomaticSeeAlso(enabled)
  @AutomaticTitleHeading(enabled)
  @AutomaticArticleSubheading(enabled)
}

## Overview

- [SwiftUI Hooks](https://github.com/ra1028/swiftui-hooks)

SwiftUI Hooks là một phiên bản được dịch ra của React Hooks, hắn đưa State và lifecycle vào trong View mà không phụ thuộc vào các Element chỉ được phép sử dụng trong struct View  như @State hoặc @ObservedObject.
Nó cho phép bạn sử dụng lại logic trạng thái giữa các View bằng cách xây dựng các hook (móc) tùy chỉnh được tạo bằng nhiều hook (móc).
Hơn nữa, các hook như useEffect cũng giải quyết được vấn đề thiếu vòng đời trong SwiftUI.

API và behavioral specs (thông số kỹ thuật hành vi) của SwiftUI Hook hoàn toàn dựa trên React Hook, vì vậy bạn có thể tận dụng kiến thức về ứng dụng web để làm lợi thế cho mình.

Hiện đã có rất nhiều tài liệu về React Hooks, các bạn có thể tham khảo và tìm hiểu thêm về Hooks.

- [React Hooks Documentation](https://reactjs.org/docs/hooks-intro.html)  
- [Youtube Video](https://www.youtube.com/watch?v=dpw9EHDh2bM)

### Section

@Links(visualStyle: detailedGrid) {
  - <doc:BeforeStarted>
  - <doc:Introduction>
  - <doc:GettingStarted>
  - <doc:BuildingYourOwnHooks>
  - <doc:RulesHooks>
  - <doc:ShouldWeUsingHooks>
}


<!--## Topics-->

<!--### Essentials-->
<!--- <doc:MeetHooks>-->
<!--- <doc:TodoHookBasic>-->
<!--- <doc:TodoHookNetwork>-->
<!--- <doc:TodoHookAdvance>-->
