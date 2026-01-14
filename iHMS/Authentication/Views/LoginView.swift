import SwiftUI

struct LoginView: View {

    @EnvironmentObject var authVM: AuthViewModel
    let onSwitchToSignup: () -> Void

    @State private var email = ""
    @State private var password = ""

    private var isLoginDisabled: Bool {
        authVM.isLoading || email.isEmpty || password.isEmpty
    }

    var body: some View {
        VStack(spacing: 32) {

            Spacer(minLength: 40)
            VStack(spacing: 8) {
                Text("Sign in")
                    .font(.largeTitle.weight(.semibold))

                Text("Continue to your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {

                TextField("Email address", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .textContentType(.emailAddress)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(uiColor: .separator).opacity(0.25))
                    )

                SecureField("Password", text: $password)
                    .textContentType(.password)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(uiColor: .separator).opacity(0.25))
                    )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28)
                    .stroke(Color(uiColor: .separator).opacity(0.3))
            )
            Button {
                Task {
                    await authVM.login(email: email, password: password)
                }
            } label: {
                HStack {
                    if authVM.isLoading {
                        ProgressView()
                    } else {
                        Text("Sign In")
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(isLoginDisabled ? .gray : .accentColor)
            .disabled(isLoginDisabled)
            VStack(spacing: 12) {

                Button("Forgot password?") {
                    Task {
                        await authVM.sendResetPasswordEmail(email: email)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .disabled(email.isEmpty)
            }
            if let error = authVM.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            Spacer()
        }
        .padding()
        .background(Color(uiColor: .systemBackground))
        .animation(.easeInOut, value: authVM.isLoading)
    }
}
