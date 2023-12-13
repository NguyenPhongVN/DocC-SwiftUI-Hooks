import SwiftUI
@_exported import Hooks
@_exported import DocCHooks
@_exported import IdentifiedCollections
@_exported import MCombineRequest
@_exported import MWebSocket

@main
struct ExamplesApp: App {
  var body: some Scene {
    WindowGroup {
      NavigationView {
        List {
          
          NavigationLink {
            CodeDemo()
          } label: {
            Text("CodeDemo")
          }

          NavigationLink {
            ExamplesView()
          } label: {
            Text("Example")
          }
          
          NavigationLink {
            TodoHookBasic()
          } label: {
            Text("Basic")
          }

          
          NavigationLink {
            TodoHookNetwork()
          } label: {
            Text("Network")
          }
          
          NavigationLink {
            HookTodoPro()
          } label: {
            Text("Advance")
          }
          
        }
      }
    }
  }
}

