//import SwiftUI
//import Supabase
//
//struct SetPasswordView: View {
//
//    @EnvironmentObject var authVM: AuthViewModel
//
//    @State private var password = ""
//    @State private var confirmPassword = ""
//    @State private var isLoading = false
//    @State private var errorMessage: String?
//    @State private var userEmail: String = ""
//
//    private let supabase = SupabaseManager.shared.client
//
//    var body: some View {
//        NavigationStack {
//            ScrollView {
//                VStack(spacing: 24) {
//
//                    Image(systemName: "lock.shield.fill")
//                        .font(.system(size: 48))
//                        .foregroundColor(.blue)
//                        .padding(.top, 20)
//
//                    Text("Set Your Password")
//                        .font(.title.bold())
//                        .multilineTextAlignment(.center)
//
//                    if !userEmail.isEmpty {
//                        Text(userEmail)
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                            .multilineTextAlignment(.center)
//                    }
//
//                    Text("""
//                    You’ve been invited as a staff member.
//
//                    For security reasons, you need to create a password before accessing the system.
//                    """)
//                    .font(.body)
//                    .foregroundColor(.secondary)
//                    .multilineTextAlignment(.center)
//                    .padding(.horizontal)
//
//                    VStack(spacing: 16) {
//
//                        SecureField("New password", text: $password)
//                            .textContentType(.newPassword)
//                            .padding()
//                            .background(Color(.secondarySystemBackground))
//                            .cornerRadius(10)
//
//                        SecureField("Confirm password", text: $confirmPassword)
//                            .textContentType(.newPassword)
//                            .padding()
//                            .background(Color(.secondarySystemBackground))
//                            .cornerRadius(10)
//
//                        Text("Password must be at least 6 characters long.")
//                            .font(.caption)
//                            .foregroundColor(.secondary)
//                            .frame(maxWidth: .infinity, alignment: .leading)
//                    }
//                    .padding(.horizontal)
//
//                    if let errorMessage {
//                        Text(errorMessage)
//                            .foregroundColor(.red)
//                            .font(.callout)
//                            .multilineTextAlignment(.center)
//                            .padding(.horizontal)
//                    }
//
//                    Button {
//                        Task { await setPassword() }
//                    } label: {
//                        HStack {
//                            if isLoading {
//                                ProgressView()
//                            } else {
//                                Text("Save & Continue").bold()
//                            }
//                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(isFormValid ? Color.blue : Color.gray)
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                    }
//                    .disabled(!isFormValid || isLoading)
//                    .padding(.horizontal)
//
//                    Spacer(minLength: 30)
//                }
//            }
//            .navigationTitle("Security Setup")
//            .navigationBarTitleDisplayMode(.inline)
//            .task {
//                do {
//                    let session = try await supabase.auth.session
//                    userEmail = session.user.email ?? ""
//                } catch {
//                    userEmail = ""
//                }
//            }
//        }
//    }
//
//    private var isFormValid: Bool {
//        password.count >= 6 && password == confirmPassword
//    }
//
//    private func setPassword() async {
//        isLoading = true
//        errorMessage = nil
//
//        do {
//            try await supabase.auth.update(
//                user: UserAttributes(password: password)
//            )
//
//            let session = try await supabase.auth.session
//            let user = session.user
//
//            let fullName =
//                user.userMetadata["full_name"]?.stringValue
//                ?? user.email
//                ?? "Staff"
//
//            let departmentId =
//                user.userMetadata["department_id"]?.stringValue
//                ?? "Nurse"
//
//            let staff = StaffInsertDTO(
//                id: user.id.uuidString,
//                full_name: fullName,
//                email: user.email ?? "",
//                department_id: departmentId,
//                designation: nil,
//                phone: nil
//            )
//
//            try await supabase
//                .from("staff")
//                .upsert(staff, onConflict: "id")
//                .execute()
//
//            let profile = ProfileInsertDTO(
//                id: user.id.uuidString,
//                full_name: fullName,
//                email: user.email ?? "",
//                role: "staff",
//                is_active: true,
//                has_set_password: true
//            )
//
//            try await supabase
//                .from("profiles")
//                .upsert(profile, onConflict: "id")
//                .execute()
//
//            await authVM.restoreSession()
//
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//
//        isLoading = false
//    }
//}
import SwiftUI
import Supabase

enum PasswordFlow {
    case onboarding
    case reset
}

struct SetPasswordView: View {

    let flow: PasswordFlow
    @EnvironmentObject var authVM: AuthViewModel

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var email = ""

    private let supabase = SupabaseManager.shared.client

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {

                Image(systemName: flow == .reset ? "lock.rotation" : "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)

                Text(flow == .reset ? "Reset Password" : "Set Your Password")
                    .font(.title.bold())

                if !email.isEmpty {
                    Text(email)
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 12) {
                    SecureField("New password", text: $password)
                    SecureField("Confirm password", text: $confirmPassword)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(14)

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }

                Button(flow == .reset ? "Update Password" : "Save & Continue") {
                    Task { await setPassword() }
                }
                .disabled(!isValid || isLoading)
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .task { await loadEmail() }
        }
    }

    private var isValid: Bool {
        password.count >= 6 && password == confirmPassword
    }

    private func loadEmail() async {
        email = (try? await supabase.auth.session.user.email) ?? ""
    }

//    // 🚀 CRITICAL FIX HERE
//    private func setPassword() async {
//        isLoading = true
//        errorMessage = nil
//
//        do {
//            // 1️⃣ Update Supabase auth password
//            try await supabase.auth.update(
//                user: UserAttributes(password: password)
//            )
//
//            // 2️⃣ Mark onboarding complete in DB
//            if flow == .onboarding {
//                let userId = try await supabase.auth.session.user.id
//
//                try await supabase
//                    .from("profiles")
//                    .update(["has_set_password": true])
//                    .eq("id", value: userId.uuidString)
//                    .execute()
//            }
//
//            // 3️⃣ HARD RESET AUTH STATE (THIS WAS MISSING)
//            authVM.showResetPassword = false
//            authVM.isInPasswordRecoveryFlow = false
//            authVM.mustSetPassword = false
//
//            await authVM.loadUserRole()
//            
//            // 4️⃣ FORCE OVERRIDE: We just set the password, so ignore potential stale DB state
//            if flow == .onboarding {
//                authVM.mustSetPassword = false
//            }
//
//            authVM.isAuthenticated = true
//            authVM.isAuthResolved = true
//
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//
//        isLoading = false
//    }
    // 🚀 FINAL & SAFE SET PASSWORD
    private func setPassword() async {
        isLoading = true
        errorMessage = nil

        do {
            // 1️⃣ Update password in Supabase Auth
            try await supabase.auth.update(
                user: UserAttributes(password: password)
            )

            let session = try await supabase.auth.session
            let user = session.user

            let userId = user.id.uuidString
            let email = user.email ?? ""

            // 2️⃣ ONBOARDING FLOW → CREATE STAFF + PROFILE
            if flow == .onboarding {

                let fullName =
                    user.userMetadata["full_name"]?.stringValue
                    ?? email

                let departmentId =
                    user.userMetadata["department_id"]?.stringValue
                    ?? "Nurse"

                // 🔹 STAFF UPSERT
                let staff = StaffInsertDTO(
                    id: userId,
                    full_name: fullName,
                    email: email,
                    department_id: departmentId,
                    designation: nil,
                    phone: nil
                )

                try await supabase
                    .from("staff")
                    .upsert(staff, onConflict: "id")
                    .execute()

                // 🔹 PROFILE UPSERT
                let profile = ProfileInsertDTO(
                    id: userId,
                    full_name: fullName,
                    email: email,
                    role: "staff",
                    is_active: true,
                    has_set_password: true
                )

                try await supabase
                    .from("profiles")
                    .upsert(profile, onConflict: "id")
                    .execute()
            }
            else {
                // 3️⃣ RESET FLOW → just mark password set
                try await supabase
                    .from("profiles")
                    .update(["has_set_password": true])
                    .eq("id", value: userId)
                    .execute()
            }

            // 4️⃣ 🔥 HARD EXIT ALL PASSWORD STATES (CRITICAL)
            authVM.showResetPassword = false
            authVM.isInPasswordRecoveryFlow = false
            authVM.mustSetPassword = false

            // 5️⃣ FORCE AUTH STATE (avoid JWT / restoreSession loop)
            authVM.isAuthenticated = true
            authVM.isAuthResolved = true

            await authVM.loadUserRole()

        } catch {
            print("❌ Set password failed:", error)
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

}
