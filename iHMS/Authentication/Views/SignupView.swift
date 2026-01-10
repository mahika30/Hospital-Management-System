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

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                Spacer(minLength: 30)

                VStack(spacing: 20) {

                    VStack(spacing: 6) {
                        Text("Create Account")
                            .font(.largeTitle.bold())

                        Text("Join iHMS to manage your health")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 14) {

                        TextField("Full Name", text: $fullName)
                            .textContentType(.name)
                            .padding()
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 14)
                            )

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
                            .textContentType(.newPassword)
                            .padding()
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 14)
                            )

                        TextField("Phone Number", text: $phoneNumber)
                            .keyboardType(.phonePad)
                            .textContentType(.telephoneNumber)
                            .padding()
                            .background(
                                .ultraThinMaterial,
                                in: RoundedRectangle(cornerRadius: 14)
                            )
                    }

                    HStack(spacing: 12) {

                        Text("Date of Birth")
                            .font(.footnote)
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
                    .padding(.horizontal, 12)
                    .padding(.vertical, 14)
                    .background(
                        .ultraThinMaterial,
                        in: RoundedRectangle(cornerRadius: 14)
                    )

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
                                    .tint(.white)
                            } else {
                                Text("Create Account")
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
                    .disabled(authVM.isLoading)

                    if let error = authVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Button {
                        onSwitchToLogin()
                    } label: {
                        Text("Already have an account? Login")
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

                Spacer(minLength: 40)
            }
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
