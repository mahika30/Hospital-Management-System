//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        AppRouter()
//    }
//}
//
import SwiftUI

struct ContentView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var didRestore = false

    var body: some View {
        AppRouter()
            .task {
                guard !didRestore else { return }
                didRestore = true
                await authVM.restoreSession()
            }
    }
}
