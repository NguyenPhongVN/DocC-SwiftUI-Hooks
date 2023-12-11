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

struct ExamplesView: View {
  
  var body: some View {
    HookScope {
      @HState
      var todos: IdentifiedArrayOf<Todo> = .mock
      List {
        ForEach(todos) { item in
          
        }
      }
    }
  }
}
