import SwiftUI

//struct ContentView: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//
//    var body: some View {
//        Group {
//            if authVM.isAuthenticated {
//                AppRouter()
//            } else {
//                AuthContainerView()
//            }
//        }
//    }
//}
struct ContentView: View {
    var body: some View {
        AppRouter()
    }
}

