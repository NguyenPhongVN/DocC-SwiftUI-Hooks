import SwiftUI
import Hooks

struct HookState: View {
  
  var body: some View {
    HookScope {
      let text = useState(0)
    }
  }
}
