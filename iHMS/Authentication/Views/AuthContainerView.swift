import SwiftUI
struct AuthSheetContainer: View {

    let initialMode: LandingView.AuthMode
    @State private var isLogin: Bool

    init(initialMode: LandingView.AuthMode) {
        self.initialMode = initialMode
        self._isLogin = State(initialValue: initialMode == .login)
    }

    var body: some View {
        ZStack {

            if isLogin {
                LoginView(onSwitchToSignup: {
                    withAnimation(.spring()) {
                        isLogin = false
                    }
                })
                .transition(.move(edge: .leading).combined(with: .opacity))
            } else {
                SignupView(onSwitchToLogin: {
                    withAnimation(.spring()) {
                        isLogin = true
                    }
                })
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.85), value: isLogin)
    }
}
