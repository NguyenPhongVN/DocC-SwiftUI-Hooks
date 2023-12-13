import SwiftUI

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
      
      @HState
      var iscollapsedAll = true
      
      @HState
      var text = ""
      
      List {
        HStack {
          TextField("name", text: $text)
          Button {
            todos.append(Todo(id: UUID(), text: text, isCompleted: false))
            text = ""
          } label: {
            Image(systemName: "plus")
          }
          .disabled(text.isEmpty)
        }
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
            
            let _ = useLayoutEffect(.preserved(by: iscollapsedAll)) {
              iscollapsed = iscollapsedAll
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
      .navigationBarItems(
        trailing:
          Toggle("collapsed", isOn: $iscollapsedAll)
          .toggleStyle(.switch)
      )
    }
  }
}

#Preview {
  ExamplesView()
}
