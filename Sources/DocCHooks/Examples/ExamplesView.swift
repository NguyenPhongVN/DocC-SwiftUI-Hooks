import SwiftUI
import IdentifiedCollections
import Hooks

private struct Todo: Hashable, Identifiable {
  var id: UUID
  var text: String
  var isCompleted: Bool
}

// MARK: Mock Data
extension IdentifiedArray where ID == Todo.ID, Element == Todo {
  static let mock: Self = [
    Todo(
      id: UUID(),
      text: "A",
      isCompleted: false
    ),
    Todo(
      id: UUID(),
      text: "B",
      isCompleted: true
    ),
    Todo(
      id: UUID(),
      text: "C",
      isCompleted: false
    ),
    Todo(
      id: UUID(),
      text: "D",
      isCompleted: true
    ),
  ]
}

/// We use `useFlagUpdated` to cache key update in` HookUpdateStrategy`. if condition == true, flag will toggle, and return new key to  HookUpdateStrategy.
/// It wil call once time when init, and then if only condition == true, hook will updates state.
public func useFlagUpdated(_ condition: Bool? = false) -> Bool {
  @HState var flag = false
  if condition == true {
    flag.toggle()
  }
  return flag
}

struct ExamplesView: View {
  var body: some View {
    HookScope {
      @HState
      var todos: IdentifiedArrayOf<Todo> = .mock
      List {
        ForEach(todos) { item in
          HookScope {
            @HState var iscollapsed = true
            
            let (phase, perform) = useAsyncRefresh { () -> Int in
              try? await Task.sleep(seconds: 2)
              return Int.random(in: 1...100)
            }
            let _ = useLayoutEffect(.preserved(by: iscollapsed)) {
              if !iscollapsed {
                Task { await perform() }
                print("Call Perform")
              }
              return nil
            }
            
            VStack {
              HStack {
                Text(item.text)
                Color.white.opacity(0.01)
              }
              .onTapGesture {
                withAnimation {
                  iscollapsed.toggle()
                }
              }
              
              if !iscollapsed {
                switch phase {
                  case .success(let value):
                    Text(value.description)
                  default:
                    ProgressView()
                }
              }
            }
          }
        }
      }
    }
  }
}

#Preview {
  ExamplesView()
}
