import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authVM: AuthViewModel
    let onSwitchToSignup: () -> Void

    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 20) {

                VStack(spacing: 6) {
                    Text("Welcome Back")
                        .font(.largeTitle.bold())

                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {

                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .textContentType(.emailAddress)
                        .padding()
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 14)
                        )

                    SecureField("Password", text: $password)
                        .textContentType(.password)
                        .padding()
                        .background(
                            .ultraThinMaterial,
                            in: RoundedRectangle(cornerRadius: 14)
                        )
                }

                Button {
                    Task {
                        await authVM.login(email: email, password: password)
                    }
                } label: {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Login")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .background(
                    LinearGradient(
                        colors: [.teal, .mint],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .foregroundColor(.white)
                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)

                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                Button {
                    onSwitchToSignup()
                } label: {
                    Text("Create new account")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(.thinMaterial)
            )
            .padding(.horizontal)

            Spacer()
        }
        .background {
            LinearGradient(
                colors: [
                    Color.teal.opacity(0.18),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        }
    }
}
