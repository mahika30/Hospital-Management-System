//import Foundation
//import Combine
//import Supabase
//
//enum UserRole: String {
//    case patient
//    case staff
//    case admin
//}
//
//@MainActor
//final class AuthViewModel: ObservableObject {
//
//    @Published var isAuthenticated = false
//    @Published var userRole: UserRole?
//    @Published var mustSetPassword = false
//    @Published var isAuthResolved = false
//
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    private let supabase = SupabaseManager.shared.client
//
//    init() {
//        Task { await restoreSession() }
//    }
//
//    func restoreSession() async {
//        errorMessage = nil
//        isAuthResolved = false
//
//        do {
//            let session = try await supabase.auth.session
//
//            guard !session.isExpired else {
//                resetAuthState()
//                isAuthResolved = true
//                return
//            }
//
//            isAuthenticated = true
//            await loadUserRole()
//            isAuthResolved = true
//
//        } catch {
//            resetAuthState()
//            isAuthResolved = true
//        }
//    }
//
//
//    private func resetAuthState() {
//        isAuthenticated = false
//        userRole = nil
//        mustSetPassword = false
//    }
//
//    func signUp(
//        email: String,
//        password: String,
//        fullName: String,
//        phoneNumber: String?,
//        dateOfBirth: Date?,
//        gender: Gender?
//    ) async {
//
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            try await supabase.auth.signUp(email: email, password: password)
//            try await supabase.auth.signIn(email: email, password: password)
//
//            let session = try await supabase.auth.session
//            let userId = session.user.id
//
//            try await PatientService().createPatient(
//                id: userId,
//                fullName: fullName,
//                email: email,
//                phoneNumber: phoneNumber,
//                dateOfBirth: dateOfBirth,
//                gender: gender
//            )
//
//            let profile = ProfileInsertDTO(
//                id: userId.uuidString,
//                full_name: fullName,
//                email: email,
//                role: "patient",
//                is_active: true,
//                has_set_password: true
//            )
//
//            try await supabase
//                .from("profiles")
//                .insert(profile)
//                .execute()
//
//            await restoreSession()
//
//        } catch {
//            errorMessage = error.localizedDescription
//            resetAuthState()
//        }
//    }
//    func login(email: String, password: String) async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            try await supabase.auth.signIn(email: email, password: password)
//            await restoreSession()
//        } catch {
//            if error.localizedDescription.localizedCaseInsensitiveContains("Invalid login credentials") {
//                errorMessage = "Invalid username or password"
//            } else {
//                errorMessage = error.localizedDescription
//            }
//            resetAuthState()
//        }
//    }
//    func handleAuthCallback(url: URL) async {
//        guard
//            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//            let code = components.queryItems?
//                .first(where: { $0.name == "code" })?
//                .value
//        else {
//            errorMessage = "Invalid auth callback"
//            return
//        }
//
//        do {
//            try await supabase.auth.exchangeCodeForSession(authCode: code)
//            await restoreSession()
//            userRole = role
//
//        } catch {
//            mustSetPassword = true
//            userRole = .staff
//        }
//    }
//
//
//    func signOut() async {
//        try? await supabase.auth.signOut()
//        resetAuthState()
//    }
//
//    func currentUserId() async -> UUID? {
//        try? await supabase.auth.session.user.id
//    }
//    func currentUserName() async -> String {
//        do {
//            let session = try await supabase.auth.session
//            let user = session.user
//
//            let profile: ProfileNameDTO = try await supabase
//                .from("profiles")
//                .select("full_name")
//                .eq("id", value: user.id.uuidString)
//                .single()
//                .execute()
//                .value
//
//            return profile.full_name
//
//        } catch {
//            if case let .string(name)? =
//                try? await supabase.auth.session.user.userMetadata["full_name"] {
//                return name
//            }
//
//            return "Admin"
//        }
//    }
//
//
//
//}
import Foundation
import Combine
import Supabase

enum UserRole: String {
    case patient
    case staff
    case admin
}

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Auth State
    @Published var isAuthenticated = false
    @Published var userRole: UserRole?
    @Published var mustSetPassword = false
    @Published var isAuthResolved = false

    // Password recovery
    @Published var showResetPassword = false
    @Published var isInPasswordRecoveryFlow = false

    // UI
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared.client
    
    func forceClearAuthState() async {
        try? await supabase.auth.signOut()

        isAuthenticated = false
        userRole = nil
        mustSetPassword = false
        isInPasswordRecoveryFlow = false
        showResetPassword = false
        isAuthResolved = true
    }


//    // MARK: - Restore Session (SAFE)
//
//    func restoreSession() async {
//
//        // 🚫 Never override reset / onboarding flows
//        if isInPasswordRecoveryFlow || mustSetPassword {
//            isAuthResolved = true
//            return
//        }
//
//        isAuthResolved = false
//        errorMessage = nil
//
//        do {
//            let session = try await supabase.auth.session
//
//            guard !session.isExpired else {
//                resetAuthState()
//                isAuthResolved = true
//                return
//            }
//
//            isAuthenticated = true
//            await loadUserRole()
//            isAuthResolved = true
//
//        } catch {
//            resetAuthState()
//            isAuthResolved = true
//        }
//    }
    
    func restoreSession() async {

        // 🚫 Only block recovery flow
        if isInPasswordRecoveryFlow {
            isAuthResolved = true
            return
        }

        isAuthResolved = false
        errorMessage = nil

        do {
            let session = try await supabase.auth.session

            guard !session.isExpired else {
                resetAuthState()
                isAuthResolved = true
                return
            }

            isAuthenticated = true
            await loadUserRole()
            isAuthResolved = true

        } catch {
            resetAuthState()
            isAuthResolved = true
        }
    }


    private func resetAuthState() {
        isAuthenticated = false
        userRole = nil
        mustSetPassword = false
        isInPasswordRecoveryFlow = false
        showResetPassword = false
    }

    // MARK: - Signup (Patients)

    func signUp(
        email: String,
        password: String,
        fullName: String,
        phoneNumber: String?,
        dateOfBirth: Date?,
        gender: Gender?
    ) async {

        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signUp(email: email, password: password)
            try await supabase.auth.signIn(email: email, password: password)

            let session = try await supabase.auth.session
            let userId = session.user.id

            try await PatientService().createPatient(
                id: userId,
                fullName: fullName,
                email: email,
                phoneNumber: phoneNumber,
                dateOfBirth: dateOfBirth,
                gender: gender
            )

            let profile = ProfileInsertDTO(
                id: userId.uuidString,
                full_name: fullName,
                email: email,
                role: "patient",
                is_active: true,
                has_set_password: true
            )

            try await supabase
                .from("profiles")
                .insert(profile)
                .execute()

            await restoreSession()

        } catch {
            errorMessage = error.localizedDescription
            resetAuthState()
        }
    }

    // MARK: - Login

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signIn(email: email, password: password)
            await restoreSession()
        } catch {
            errorMessage = "Invalid email or password"
            resetAuthState()
        }
    }

    // MARK: - Forgot Password (FIXED)

    func sendResetPasswordEmail(email: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            errorMessage = "Please enter your email"
            return
        }

        do {
            try await supabase.auth.resetPasswordForEmail(
                cleanEmail,
                redirectTo: URL(string: "ihms://auth-callback?type=recovery")!
            )

            errorMessage = "If this email exists, a reset link has been sent."
        } catch {
            errorMessage = "Unable to send reset email. Please try again."
        }

    }


    // MARK: - Deep Link Handler (SINGLE ENTRY POINT)

    func handleDeepLink(url: URL) async {
        print("🔗 Deep Link: \(url.absoluteString)")

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []
        let code = queryItems.first(where: { $0.name == "code" })?.value
        
        // Check triggers
        let isRecovery = url.absoluteString.contains("type=recovery")

        // 1️⃣ PASSWORD RESET FLOW
        if isRecovery {
            print("🛟 Recovery Flow Detected")
            // If PKCE code exists, exchange it first
            if let code = code {
                await handlePasswordRecovery(code: code)
            } else {
                // Implicit flow (fragments) or just a link click
                await handlePasswordRecovery(url: url)
            }
            return
        }

        // 2️⃣ MAGIC LINK / INVITE FLOW (No recovery tag)
        if let code = code {
            print("✨ Magic Link Flow Detected")
            await handleAuthCode(code: code)
            return
        }
    }

    // Handle PKCE Recovery (Code)
    private func handlePasswordRecovery(code: String) async {
        do {
            isInPasswordRecoveryFlow = true
            isAuthenticated = false // Hide main content

            // Exchange code for session
            try await supabase.auth.exchangeCodeForSession(authCode: code)

            // Show Reset UI
            showResetPassword = true
            isAuthResolved = true

        } catch {
            print("Recovery Code Error: \(error)")
            errorMessage = "Reset link expired or invalid."
            resetAuthState()
        }
    }

    // Handle Implicit Recovery (URL/Fragments)
    private func handlePasswordRecovery(url: URL) async {
        do {
            isInPasswordRecoveryFlow = true
            isAuthenticated = false

            // Parse session from URL (Implicit)
            try await supabase.auth.session(from: url)

            showResetPassword = true
            isAuthResolved = true

        } catch {
            print("Recovery URL Error: \(error)")
            errorMessage = "Reset link invalid."
            resetAuthState()
        }
    }

    private func handleAuthCode(code: String) async {
        do {
            try await supabase.auth.exchangeCodeForSession(authCode: code)

            // 🔑 Decide route from DB state
            await loadUserRole()
            isAuthenticated = true
            isAuthResolved = true

        } catch {
            print("Auth Code Error: \(error)")
            errorMessage = "Authentication failed"
        }
    }

    func loadUserRole() async {
        guard let userId = try? await supabase.auth.session.user.id else {
            resetAuthState()
            return
        }

        do {
            let profile: ProfileDTO = try await supabase
                .from("profiles")
                .select("role, is_active, has_set_password")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value

            guard profile.is_active else {
                errorMessage = "Account inactive"
                resetAuthState()
                return
            }

            guard let role = UserRole(rawValue: profile.role) else {
                resetAuthState()
                return
            }

            userRole = role

            if role == .staff && profile.has_set_password == false {
                mustSetPassword = true
                return
            }

            mustSetPassword = false

        } catch {
            // invited doctor → onboarding
            mustSetPassword = true
            userRole = .staff
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        resetAuthState()
    }

    func currentUserId() async -> UUID? {
        try? await supabase.auth.session.user.id
    }

    func currentUserName() async -> String {
        do {
            let session = try await supabase.auth.session
            let user = session.user

            let profile: ProfileNameDTO = try await supabase
                .from("profiles")
                .select("full_name")
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
                .value

            return profile.full_name
        } catch {
            return "Admin"
        }
    }

}
