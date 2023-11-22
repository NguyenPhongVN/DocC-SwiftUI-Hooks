import SwiftUI
import Hooks
import IdentifiedCollections
import MCombineRequest
import MWebSocket
import RealmSwift

private struct WSTodoAction: Codable {
  var action: Action
  var todo: Todo
}

private extension WSTodoAction {
  enum Action: String, Codable {
    case update
    case create
    case delete
  }
}

// MARK: Model
@objc(RealmTodo)
private class RealmTodo: RealmSwift.Object, Identifiable {
  @Persisted(primaryKey: true) var id: UUID
  @Persisted var text: String = ""
  @Persisted var isCompleted: Bool = false
}

private extension RealmTodo {
  func toTodo() -> Todo {
    Todo(id: id, text: text, isCompleted: isCompleted)
  }
}

private struct Todo: Codable, Hashable, Identifiable, Equatable {
  var id: UUID
  var text: String
  var isCompleted: Bool
}

private extension Todo {
  func toRealmTodo() -> RealmTodo {
    let realmTodo = RealmTodo()
    realmTodo.id = id
    realmTodo.text = text
    realmTodo.isCompleted = isCompleted
    return realmTodo
  }
}


private enum Filter: CaseIterable, Hashable, Equatable {
  case all
  case completed
  case uncompleted
}

private struct Stats: Equatable {
  let total: Int
  let totalCompleted: Int
  let totalUncompleted: Int
  let percentCompleted: Double
}


// MARK: Hook

private func useReadTodoDatabase() -> AsyncPhase<IdentifiedArrayOf<Todo>, any Error> {
  usePublisherPhaseDatabase(RealmTodo.self)
    .map { results in
      results.toIdentifiedArray().compactMap({$0.toTodo()}).toIdentifiedArray()
    }
}

private func useNextPhaseValueTodo() -> IdentifiedArrayOf<Todo> {
  useNextPhaseValue(useReadTodoDatabase()) ?? []
}

// MARK: Database

private func useUpdateTodoDatabase(_ model: Todo?) {
  guard let model else { return }
  let items = useObjectDatabase(RealmTodo.self).toArray().map({$0.toTodo()})
  if items.contains(model) {
    return
  }
  useUpdateDatabase(model.toRealmTodo())
}

private func useUpdateTodoDatabase(_ models: IdentifiedArrayOf<Todo>?) {
  guard let models, !models.isEmpty else { return }
  for item in models {
    useUpdateTodoDatabase(item)
  }
}

private func useDeleteTodoDatabase(_ id: RealmTodo.ID) {
  useDeleteDatabase(RealmTodo.self, id)
}

private func useDeleteObjectTodoDatabase() {
  useDeleteDatabase(RealmTodo.self)
}

// MARK: View

private struct TodoStats: View {
  
  var body: some View {
    HookScope {
      let todos = useNextPhaseValueTodo()
      let total = todos.count
      let totalCompleted = todos.filter(\.isCompleted).count
      let totalUncompleted = todos.filter { !$0.isCompleted }.count
      let percentCompleted = total <= 0 ? 0 : (Double(totalCompleted) / Double(total))
      let stats = Stats(
        total: total,
        totalCompleted: totalCompleted,
        totalUncompleted: totalUncompleted,
        percentCompleted: percentCompleted
      )
      VStack(alignment: .leading, spacing: 4) {
        stat("Total", "\(stats.total)")
        stat("Completed", "\(stats.totalCompleted)")
        stat("Uncompleted", "\(stats.totalUncompleted)")
        stat("Percent Completed", "\(Int(stats.percentCompleted * 100))%")
      }
      .padding(.vertical)
    }
  }
  
  private func stat(_ title: String, _ value: String) -> some View {
    HStack {
      Text(title) + Text(":")
      Spacer()
      Text(value)
    }
  }
}

private struct TodoCreator: View {
  
  var body: some View {
    HookScope {
      
      @HState var text = ""

      HStack {
        TextField("Enter your todo", text: $text)
#if os(iOS) || os(macOS)
          .textFieldStyle(.plain)
#endif
        Button {
          Task {
            let data = try await MRequest {
              RUrl("http://127.0.0.1:8080")
                .withPath("todos")
              Rbody(Todo(id: UUID(), text: text, isCompleted: false))
              RMethod(.post)
              REncoding(JSONEncoding.default)
            }
              .printCURLRequest()
              .data
            useUpdateTodoDatabase(data.toModel(Todo.self))
          }
        } label: {
          Text("Add")
            .bold()
            .foregroundColor(text.isEmpty ? .gray : .green)
        }
        .disabled(text.isEmpty)
      }
      .padding(.vertical)
    }
  }
}

private struct TodoFilters: View {
  
  let filter: Binding<Filter>
  
  var body: some View {
    HookScope {
      Picker("Filter", selection: filter) {
        ForEach(Filter.allCases, id: \.self) { filter in
          switch filter {
            case .all:
              Text("All")
            case .completed:
              Text("Completed")
            case .uncompleted:
              Text("Uncompleted")
          }
        }
      }
      .padding(.vertical)
#if !os(watchOS)
      .pickerStyle(.segmented)
#endif
    }
  }
}


private struct TodoItem: View {
  
  fileprivate let todoID: UUID
  
  fileprivate init(todoID: UUID) {
    self.todoID = todoID
  }
  
  var body: some View {
    HookScope {
      
      let todos = useNextPhaseValueTodo()
      let todo: Todo? = todos.filter({$0.id == todoID}).first
      
      @MHState var text = ""
      
      @MHState var isCompleted = false
      
      let _ = $text
        .onChange { newValue in
          if var todo = todo {
            todo.text = newValue
            Task {
              let data: Data = try await MRequest {
                RUrl("http://127.0.0.1:8080")
                  .withPath("todos")
                  .withPath(todo.id.uuidString)
                Rbody(todo.toData())
                RMethod(.post)
                REncoding(JSONEncoding.default)
              }
                .printCURLRequest()
                .data
              useUpdateTodoDatabase(data.toModel(Todo.self))
            }
          }
        }
      
      let _ =  $isCompleted
        .onChange { newValue in
          if var todo = todo {
            todo.isCompleted = newValue
            Task {
              let data: Data = try await MRequest {
                RUrl("http://127.0.0.1:8080")
                  .withPath("todos")
                  .withPath(todo.id.uuidString)
                Rbody(todo.toData())
                RMethod(.post)
                REncoding(JSONEncoding.default)
              }
                .printCURLRequest()
                .data
              useUpdateTodoDatabase(data.toModel(Todo.self))
            }
          }
        }
      
      let _ = useMemo(.preserved(by: todo)) {
        if let _text = todo?.text {
          let _ = $text.send(_text) /// send value doesn't send emit to onChange
        }
        if let _isCompleted = todo?.isCompleted { /// send value doesn't send emit to onChange
          let _ = $isCompleted.send(_isCompleted)
        }
      }
      
      if todo != nil {
        Toggle(isOn: $isCompleted.value) {
          TextField("", text: $text.value) {
          }
          .textFieldStyle(.plain)
#if os(iOS) || os(macOS)
          .textFieldStyle(.roundedBorder)
#endif
        }
        .padding(.vertical, 4)
      }
    }
  }
}

struct HookTodoPro: View {
  
  @ViewBuilder
  var body: some View {
    HookScope {
      
      // websocket
      let webSocketAsyncPhase = useAsyncSequence {
        MWebSocket {
          RUrl("ws://127.0.0.1:8080/todo-list")
        }
        .toAsyncStream()
      }
      
      let _ = useLayoutEffect(.preserved(by: webSocketAsyncPhase.value)) {
        switch webSocketAsyncPhase {
          case .success(let event):
            switch event {
              case .text(let string):
                if let todoAction = string.toModel(WSTodoAction.self) {
                  switch todoAction.action {
                    case .delete:
                      useDeleteTodoDatabase(todoAction.todo.id)
                    case .update, .create:
                      useUpdateTodoDatabase(todoAction.todo)
                  }
                }
              case .binary(let data):
                if let todoAction = data.toModel(WSTodoAction.self) {
                  switch todoAction.action {
                    case .delete:
                      useDeleteTodoDatabase(todoAction.todo.id)
                    case .update, .create:
                      useUpdateTodoDatabase(todoAction.todo)
                  }
                }
              default:
                break
            }
          default:
            break
        }
        return nil
      }
      
      @HState<Filter> var filter: Filter = .all
      
      let todos = useNextPhaseValueTodo()
      let onChange: [AnyHashable] = [filter, todos]
      
      let filteredTodos = useMemo(.preserved(by: onChange)) { () -> IdentifiedArrayOf<Todo> in
        switch filter {
          case .all:
            return todos
          case .completed:
            return todos.filter(\.isCompleted)
          case .uncompleted:
            return todos.filter { !$0.isCompleted }
        }
      }
      
      // get data from backend, after that, update to realm database.
      let (_, refresher) = useAsyncPerform { () -> IdentifiedArrayOf<Todo> in
        useDeleteObjectTodoDatabase()
        let request = MRequest {
          RUrl("http://127.0.0.1:8080")
            .withPath("todos")
          RMethod(.get)
        }
        let data = try await request.data
        let models = data.toModel(IdentifiedArrayOf<Todo>.self) ?? []
        useUpdateTodoDatabase(models)
        return models
      }
      
      List {
        Section(header: Text("Information")) {
          TodoStats()
          TodoCreator()
        }
        Section(header: Text("Filters")) {
          TodoFilters(filter: $filter)
        }
        ForEach(filteredTodos, id: \.id) { todo in
          TodoItem(todoID: todo.id)
        }
        .onDelete { atOffsets in
          for index in atOffsets {
            let todo = todos[index]
            Task {
              let data: Data = try await MRequest {
                RUrl("http://127.0.0.1:8080")
                  .withPath("todos")
                  .withPath(todo.id.uuidString)
                RMethod(.delete)
              }
                .printCURLRequest()
                .data
              if let model = data.toModel(Todo.self) {
                useDeleteTodoDatabase(model.id)
              }
            }
          }
        }
        .onMove { fromOffsets, toOffset in
          
        }
      }
      .task {
        Task { @MainActor in
           await refresher()
        }
      }
      .refreshable {
        Task { @MainActor in
           await refresher()
        }
      }
      .listStyle(.sidebar)
      .toolbar {
        if filter == .all {
#if os(iOS)
          EditButton()
#endif
        }
      }
      .navigationTitle("Hook-Todos (\(filteredTodos.count.description))")
#if os(iOS)
      .navigationBarTitleDisplayMode(.inline)
#endif
    }
  }
}

#Preview {
  HookTodoPro()
}
