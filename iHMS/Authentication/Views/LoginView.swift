//import SwiftUI
//
//struct LoginView: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//    let onSwitchToSignup: () -> Void
//
//    @State private var email = ""
//    @State private var password = ""
//
//    var body: some View {
//        VStack {
//            Spacer()
//
//            VStack(spacing: 20) {
//
//                VStack(spacing: 6) {
//                    Text("Welcome Back")
//                        .font(.largeTitle.bold())
//
//                    Text("Sign in to continue")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                }
//
//                VStack(spacing: 14) {
//
//                    TextField("Email", text: $email)
//                        .keyboardType(.emailAddress)
//                        .textInputAutocapitalization(.never)
//                        .textContentType(.emailAddress)
//                        .padding()
//                        .background(
//                            .ultraThinMaterial,
//                            in: RoundedRectangle(cornerRadius: 14)
//                        )
//
//                    SecureField("Password", text: $password)
//                        .textContentType(.password)
//                        .padding()
//                        .background(
//                            .ultraThinMaterial,
//                            in: RoundedRectangle(cornerRadius: 14)
//                        )
//                }
//
//                Button {
//                    Task {
//                        await authVM.login(email: email, password: password)
//                    }
//                } label: {
//                    HStack {
//                        if authVM.isLoading {
//                            ProgressView()
//                                .tint(.white)
//                        } else {
//                            Text("Login")
//                                .font(.headline)
//                        }
//                    }
//                    .frame(maxWidth: .infinity)
//                    .padding()
//                }
//                .background(
//                    LinearGradient(
//                        colors: [.teal, .mint],
//                        startPoint: .leading,
//                        endPoint: .trailing
//                    ),
//                    in: RoundedRectangle(cornerRadius: 16)
//                )
//                .foregroundColor(.white)
//                .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
//
//                if let error = authVM.errorMessage {
//                    Text(error)
//                        .font(.caption)
//                        .foregroundStyle(.red)
//                        .multilineTextAlignment(.center)
//                }
//
//                Button {
//                    onSwitchToSignup()
//                } label: {
//                    Text("Create new account")
//                        .font(.footnote)
//                        .foregroundStyle(.secondary)
//                }
//            }
//            .padding(24)
//            .background(
//                RoundedRectangle(cornerRadius: 28)
//                    .fill(.thinMaterial)
//            )
//            .padding(.horizontal)
//
//            Spacer()
//        }
//        .background {
//            LinearGradient(
//                colors: [
//                    Color.teal.opacity(0.18),
//                    Color.clear
//                ],
//                startPoint: .top,
//                endPoint: .bottom
//            )
//            .ignoresSafeArea()
//        }
//    }
//}
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

            // MARK: - Header
            VStack(spacing: 8) {
                Text("Sign in")
                    .font(.largeTitle.weight(.semibold))

                Text("Continue to your account")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // MARK: - Card
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

            // MARK: - Primary Action
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

            // MARK: - Secondary Actions
            VStack(spacing: 12) {

                Button("Forgot password?") {
                    Task {
                        await authVM.sendResetPasswordEmail(email: email)
                    }
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .disabled(email.isEmpty)

                Divider()

                Button("Create an account") {
                    onSwitchToSignup()
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)
            }

            // MARK: - Error
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
