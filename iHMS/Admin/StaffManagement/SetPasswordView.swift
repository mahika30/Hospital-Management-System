import SwiftUI
import Supabase

struct SetPasswordView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var userEmail: String = ""

    private let supabase = SupabaseManager.shared.client

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                        .padding(.top, 20)

                    Text("Set Your Password")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    if !userEmail.isEmpty {
                        Text(userEmail)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    Text("""
                    You’ve been invited as a staff member.

                    For security reasons, you need to create a password before accessing the system.
                    """)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                    VStack(spacing: 16) {

                        SecureField("New password", text: $password)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        SecureField("Confirm password", text: $confirmPassword)
                            .textContentType(.newPassword)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)

                        Text("Password must be at least 6 characters long.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal)

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.callout)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Button {
                        Task { await setPassword() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                            } else {
                                Text("Save & Continue").bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)

                    Spacer(minLength: 30)
                }
            }
            .navigationTitle("Security Setup")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                do {
                    let session = try await supabase.auth.session
                    userEmail = session.user.email ?? ""
                } catch {
                    userEmail = ""
                }
            }
        }
    }

    private var isFormValid: Bool {
        password.count >= 6 && password == confirmPassword
    }

    private func setPassword() async {
        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.update(
                user: UserAttributes(password: password)
            )

            let session = try await supabase.auth.session
            let user = session.user

            let fullName =
                user.userMetadata["full_name"]?.stringValue
                ?? user.email
                ?? "Staff"

            let departmentId =
                user.userMetadata["department_id"]?.stringValue
                ?? "Nurse"

            let staff = StaffInsertDTO(
                id: user.id.uuidString,
                full_name: fullName,
                email: user.email ?? "",
                department_id: departmentId,
                designation: nil,
                phone: nil
            )

            try await supabase
                .from("staff")
                .upsert(staff, onConflict: "id")
                .execute()

            let profile = ProfileInsertDTO(
                id: user.id.uuidString,
                full_name: fullName,
                email: user.email ?? "",
                role: "staff",
                is_active: true,
                has_set_password: true
            )

            try await supabase
                .from("profiles")
                .upsert(profile, onConflict: "id")
                .execute()

            await authVM.restoreSession()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
