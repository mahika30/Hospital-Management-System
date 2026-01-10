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

    @Published var isAuthenticated = false
    @Published var userRole: UserRole?
    @Published var mustSetPassword = false
    @Published var isAuthResolved = false

    @Published var isLoading = false
    @Published var errorMessage: String?

    private let supabase = SupabaseManager.shared.client

    init() {
        Task { await restoreSession() }
    }

    func restoreSession() async {
        errorMessage = nil
        isAuthResolved = false

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
    }

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
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await supabase.auth.signIn(email: email, password: password)
            await restoreSession()
        } catch {
            errorMessage = error.localizedDescription
            resetAuthState()
        }
    }
    func handleAuthCallback(url: URL) async {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let code = components.queryItems?
                .first(where: { $0.name == "code" })?
                .value
        else {
            errorMessage = "Invalid auth callback"
            return
        }

        do {
            try await supabase.auth.exchangeCodeForSession(authCode: code)
            await restoreSession()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadUserRole() async {
        guard let userId = await currentUserId() else {
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

            if role == .staff && profile.has_set_password == false {
                mustSetPassword = true
                userRole = .staff
                return
            }
            mustSetPassword = false
            userRole = role

        } catch {
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
            if case let .string(name)? =
                try? await supabase.auth.session.user.userMetadata["full_name"] {
                return name
            }

            return "Admin"
        }
    }



}
