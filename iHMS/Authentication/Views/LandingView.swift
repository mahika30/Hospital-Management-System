import SwiftUI

struct LandingView: View {
    
    @State private var showAuthSheet = false
    @State private var defaultAuthMode: AuthMode = .login
    
    enum AuthMode {
        case login
        case signup
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: -100, y: -200)
                    
                    Circle()
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 350, height: 350)
                        .blur(radius: 80)
                        .offset(x: 120, y: 150)
                    
                    Circle()
                        .fill(Color.mint.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .blur(radius: 50)
                        .offset(x: -50, y: 100)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // Hero Section
                VStack(spacing: 16) {
                    Image(systemName: "staroflife.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)
                    
                    Text("iHMS")
                        .font(.system(size: 56, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                    
                    Text("Your Health, Our Priority.")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                    
                    Text("\"Healing is a matter of time, but it is sometimes also a matter of opportunity.\"")
                        .font(.callout)
                        .italic()
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                }
                .padding(.bottom, 60)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Button {
                        defaultAuthMode = .login
                        showAuthSheet = true
                    } label: {
                        Text("Log In")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(LinearGradient(colors: [.white.opacity(0.5), .white.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    }
                    .foregroundStyle(.white)
                    
                    Button {
                        defaultAuthMode = .signup
                        showAuthSheet = true
                    } label: {
                        Text("Register")
                            .font(.title3.bold())
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color(white: 0.9), Color(white: 0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .clipShape(Capsule())
                            .shadow(color: .white.opacity(0.1), radius: 10, x: 0, y: 5)
                            .overlay(
                                Capsule()
                                    .stroke(Color.white, lineWidth: 1)
                            )
                    }
                    .foregroundStyle(.black)
                    
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showAuthSheet) {
            AuthSheetContainer(initialMode: defaultAuthMode)
                .presentationDetents([.fraction(0.85), .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(35)
                .interactiveDismissDisabled(false)
        }
    }
}


struct AuthSheetContainer: View {
    let initialMode: LandingView.AuthMode
    @State private var isLogin: Bool
    
    init(initialMode: LandingView.AuthMode) {
        self.initialMode = initialMode
        self._isLogin = State(initialValue: initialMode == .login)
    }
    
    var body: some View {
        ZStack {
            // Background is handled by the sheet itself usually,
            // but we can add a subtle gradient if needed.
            // For now, standard sheet background is fine or we can customize.
            Color.clear
            
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
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: isLogin)
    }
}

#Preview {
    LandingView()
}
