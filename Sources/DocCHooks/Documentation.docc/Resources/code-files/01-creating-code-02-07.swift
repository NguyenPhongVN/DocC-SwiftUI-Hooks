import SwiftUI
import Hooks

struct HookState: View {
  
  @State var count = 0
  
  @Binding var text = ""
  
  var body: some View {
    VStack {
      Stepper("", value: $count)
      
      TextField("", text: $text)
    }
  }
}
