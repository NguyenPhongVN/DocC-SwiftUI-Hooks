import SwiftUI
import Hooks

struct HookState: View {
  
  var body: some View {
    HookScope {
      let count = useState(0)
      Stepper("", value: count)
    }
  }
}
