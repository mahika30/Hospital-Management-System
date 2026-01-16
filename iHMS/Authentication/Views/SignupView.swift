import SwiftUI

struct SignupView: View {

    @EnvironmentObject var authVM: AuthViewModel
    let onSwitchToLogin: () -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var dateOfBirth = Date()
    @State private var gender: Gender = .male

    private var isSignupDisabled: Bool {
        authVM.isLoading ||
        email.isEmpty ||
        password.isEmpty ||
        fullName.isEmpty
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {

                Spacer(minLength: 40)

                // MARK: - Header
                VStack(spacing: 8) {
                    Text("Create your account")
                        .font(.largeTitle.weight(.semibold))

                    Text("Set up your iHMS profile")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                // MARK: - Card
                VStack(spacing: 16) {

                    Group {
                        TextField("Full name", text: $fullName)
                            .textContentType(.name)

                        TextField("Email address", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .textContentType(.emailAddress)

                        SecureField("Password", text: $password)
                            .textContentType(.newPassword)

                        TextField("Phone number (optional)", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(uiColor: .separator).opacity(0.25))
                    )

                    // Date of Birth
                    HStack {
                        Text("Date of birth")
                            .foregroundStyle(.secondary)

                        Spacer()

                        DatePicker(
                            "",
                            selection: $dateOfBirth,
                            in: ...Date(),
                            displayedComponents: .date
                        )
                        .labelsHidden()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(uiColor: .tertiarySystemBackground))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color(uiColor: .separator).opacity(0.25))
                    )

                    // Gender
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        Picker("Gender", selection: $gender) {
                            ForEach(Gender.allCases) { g in
                                Text(g.rawValue.capitalized).tag(g)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
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
                        await authVM.signUp(
                            email: email,
                            password: password,
                            fullName: fullName,
                            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                            dateOfBirth: dateOfBirth,
                            gender: gender
                        )
                    }
                } label: {
                    HStack {
                        if authVM.isLoading {
                            ProgressView()
                        } else {
                            Text("Create Account")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(isSignupDisabled ? .gray : .accentColor)
                .disabled(isSignupDisabled)

                // MARK: - Error
                if let error = authVM.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }

                // MARK: - Secondary Action
                Button("Already have an account? Sign in") {
                    onSwitchToLogin()
                }
                .font(.footnote.weight(.medium))
                .foregroundStyle(.secondary)

                Spacer(minLength: 40)
            }
            .padding()
        }
        .background(Color(uiColor: .systemBackground))
        .animation(.easeInOut, value: authVM.isLoading)
    }
}
