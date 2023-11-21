import SwiftUI
import Hooks

struct HookState: View {
  
  var body: some View {
    HookScope {
      let count = useState(0)
      
      let text = useState("")
      
      let color = useMemo(.preserved(by: count.wrappedValue)) {
        UIColor(
          red: .random(in: 0...1),
          green: .random(in: 0...1),
          blue: .random(in: 0...1)
        )
      }
      
      VStack {
        Stepper("", value: count)
        
        TextField("", text: text)
        
        color
      }
    }
  }
}
