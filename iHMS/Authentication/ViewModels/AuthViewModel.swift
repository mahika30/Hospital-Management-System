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
//        do {
//            let session = try await supabase.auth.session
//            isAuthenticated = !session.isExpired
//
//            if isAuthenticated {
//                await loadUserRole()
//            }
//        } catch {
//            isAuthenticated = false
//            userRole = nil
//        }
//    }
//
//
//    // MARK: - Patient Signup (Email + Password)
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
//            try await supabase.auth.signUp(
//                email: email,
//                password: password
//            )
//
//            try await supabase.auth.signIn(
//                email: email,
//                password: password
//            )
//
//            let session = try await supabase.auth.session
//            let userId = session.user.id
//
//            // Domain: Patient
//            try await PatientService().createPatient(
//                id: userId,
//                fullName: fullName,
//                email: email,
//                phoneNumber: phoneNumber,
//                dateOfBirth: dateOfBirth,
//                gender: gender
//            )
//
//            // RBAC profile
//            let profile = ProfileInsertDTO(
//                id: userId.uuidString,
//                full_name: fullName,
//                email: email,
//                role: "patient",
//                is_active: true
//            )
//
//            try await supabase
//                .from("profiles")
//                .insert(profile)
//                .execute()
//
//            isAuthenticated = true
//            await loadUserRole()
//
//        } catch {
//            errorMessage = error.localizedDescription
//            isAuthenticated = false
//            userRole = nil
//        }
//    }
//
//    // MARK: - Login (Email + Password)
//    func login(email: String, password: String) async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            try await supabase.auth.signIn(
//                email: email,
//                password: password
//            )
//            await restoreSession()
//        } catch {
//            errorMessage = error.localizedDescription
//            isAuthenticated = false
//            userRole = nil
//        }
//    }
//
////    func handleAuthCallback(url: URL) async {
////        guard
////            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
////            let code = components.queryItems?
////                .first(where: { $0.name == "code" })?
////                .value
////        else {
////            errorMessage = "Invalid auth callback"
////            return
////        }
////
////        do {
////            try await supabase.auth.exchangeCodeForSession(authCode: code)
////            await restoreSession()
////        } catch {
////            errorMessage = error.localizedDescription
////        }
////    }
//    func handleAuthCallback(url: URL) async {
//        guard
//            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//            let code = components.queryItems?
//                .first(where: { $0.name == "code" })?.value
//        else {
//            errorMessage = "Invalid auth callback"
//            return
//        }
//
//        do {
//            try await supabase.auth.exchangeCodeForSession(authCode: code)
//            await restoreSession()
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//    }
//
//
//
//
//
//    func loadUserRole() async {
//        guard let userId = await currentUserId() else {
//            userRole = nil
//            return
//        }
//
//        do {
//            // Existing profile
//            let profile: ProfileDTO = try await supabase
//                .from("profiles")
//                .select("role, is_active")
//                .eq("id", value: userId.uuidString)
//                .single()
//                .execute()
//                .value
//
//            guard profile.is_active else {
//                errorMessage = "Account is inactive"
//                userRole = nil
//                return
//            }
//
//            userRole = UserRole(rawValue: profile.role)
//
//        } catch {
//            // First-time staff login (magic link)
//            do {
//                let session = try await supabase.auth.session
//                let user = session.user
//
//                let fullName: String
//                if case let .string(name)? = user.userMetadata["full_name"] {
//                    fullName = name
//                } else {
//                    fullName = user.email ?? "Staff"
//                }
//
//                let profile = ProfileInsertDTO(
//                    id: user.id.uuidString,
//                    full_name: fullName,
//                    email: user.email ?? "",
//                    role: "staff",
//                    is_active: true
//                )
//
//                try await supabase
//                    .from("profiles")
//                    .insert(profile)
//                    .execute()
//
//                userRole = .staff
//
//            } catch {
//                errorMessage = error.localizedDescription
//                userRole = nil
//            }
//        }
//    }
//
//    // MARK: - Sign Out
//    func signOut() async {
//        try? await supabase.auth.signOut()
//        isAuthenticated = false
//        userRole = nil
//    }
//
//    // MARK: - Current User ID
//    func currentUserId() async -> UUID? {
//        do {
//            let session = try await supabase.auth.session
//            return session.user.id
//        } catch {
//            return nil
//        }
//    }
//}
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
//    @Published var isLoading = false
//    @Published var errorMessage: String?
//
//    private let supabase = SupabaseManager.shared.client
//    @Published var mustSetPassword = false
//
//
//    init() {
//        Task { await restoreSession() }
//    }
//
//    func restoreSession() async {
//        errorMessage = nil
//
//        do {
//            let session = try await supabase.auth.session
//            isAuthenticated = !session.isExpired
//
//            if isAuthenticated {
//                await loadUserRole()
//            } else {
//                userRole = nil
//                mustSetPassword = false   // 🔥 IMPORTANT
//            }
//        } catch {
//            isAuthenticated = false
//            userRole = nil
//            mustSetPassword = false       // 🔥 IMPORTANT
//        }
//    }
//
//
//    // MARK: - Patient Signup
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
//            try await supabase.auth.signUp(
//                email: email,
//                password: password
//            )
//
//            try await supabase.auth.signIn(
//                email: email,
//                password: password
//            )
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
//            isAuthenticated = false
//            userRole = nil
//        }
//    }
//
//    // MARK: - Login (Email + Password)
//    func login(email: String, password: String) async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            try await supabase.auth.signIn(
//                email: email,
//                password: password
//            )
//            await restoreSession()
//        } catch {
//            errorMessage = error.localizedDescription
//            isAuthenticated = false
//            userRole = nil
//        }
//    }
//
//    // MARK: - Magic Link Callback
//    func handleAuthCallback(url: URL) async {
//        guard
//            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
//        else {
//            errorMessage = "Invalid auth callback"
//            return
//        }
//
//        do {
//            try await supabase.auth.exchangeCodeForSession(authCode: code)
//            await restoreSession()
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//    }
//
//    func loadUserRole() async {
//        guard let userId = await currentUserId() else {
//            userRole = nil
//            mustSetPassword = false
//            return
//        }
//
//        do {
//            let profile: ProfileDTO = try await supabase
//                .from("profiles")
//                .select("role, is_active, has_set_password")
//                .eq("id", value: userId.uuidString)
//                .single()
//                .execute()
//                .value
//
//            guard profile.is_active else {
//                errorMessage = "Account is inactive"
//                userRole = nil
//                mustSetPassword = false
//                return
//            }
//
//            guard let role = UserRole(rawValue: profile.role) else {
//                errorMessage = "Invalid role"
//                userRole = nil
//                mustSetPassword = false
//                return
//            }
//
//            // 🔐 FORCE staff to set password
//            if role == .staff && profile.has_set_password == false {
//                mustSetPassword = true
//                userRole = .staff
//                return
//            }
//
//            // ✅ Normal flow
//            mustSetPassword = false
//            userRole = role
//
//        } catch {
//            // Profile missing → first-time staff login
//            mustSetPassword = true
//            userRole = .staff
//        }
//    }
//
//
//    // MARK: - Sign Out
//    func signOut() async {
//        try? await supabase.auth.signOut()
//        isAuthenticated = false
//        userRole = nil
//    }
//
//    // MARK: - Current User ID
//    func currentUserId() async -> UUID? {
//        do {
//            let session = try await supabase.auth.session
//            return session.user.id
//        } catch {
//            return nil
//        }
//    }
//}
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
//
//        do {
//            let session = try await supabase.auth.session
//
//            guard !session.isExpired else {
//                resetAuthState()
//                return
//            }
//
//            isAuthenticated = true
//            await loadUserRole()
//
//        } catch {
//            resetAuthState()
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
//    // MARK: - Patient Signup
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
//            try await supabase.from("profiles").insert(profile).execute()
//            await restoreSession()
//
//        } catch {
//            errorMessage = error.localizedDescription
//            resetAuthState()
//        }
//    }
//
//    // MARK: - Login
//    func login(email: String, password: String) async {
//        isLoading = true
//        errorMessage = nil
//        defer { isLoading = false }
//
//        do {
//            try await supabase.auth.signIn(email: email, password: password)
//            await restoreSession()
//        } catch {
//            errorMessage = error.localizedDescription
//            resetAuthState()
//        }
//    }
//
//    // MARK: - Magic Link Callback
//    func handleAuthCallback(url: URL) async {
//        guard
//            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//            let code = components.queryItems?.first(where: { $0.name == "code" })?.value
//        else {
//            errorMessage = "Invalid auth callback"
//            return
//        }
//
//        do {
//            try await supabase.auth.exchangeCodeForSession(authCode: code)
//            await restoreSession()
//        } catch {
//            errorMessage = error.localizedDescription
//        }
//    }
//
//    func loadUserRole() async {
//        guard let userId = await currentUserId() else {
//            resetAuthState()
//            return
//        }
//
//        do {
//            let profile: ProfileDTO = try await supabase
//                .from("profiles")
//                .select("role, is_active, has_set_password")
//                .eq("id", value: userId.uuidString)
//                .single()
//                .execute()
//                .value
//
//            guard profile.is_active else {
//                errorMessage = "Account inactive"
//                resetAuthState()
//                return
//            }
//
//            guard let role = UserRole(rawValue: profile.role) else {
//                resetAuthState()
//                return
//            }
//
//            if role == .staff && profile.has_set_password == false {
//                mustSetPassword = true
//                userRole = nil
//                return
//            }
//
//            mustSetPassword = false
//            userRole = role
//
//        } catch {
//            // ❗ NO PROFILE = DO NOTHING
//            mustSetPassword = false
//            userRole = nil
//        }
//    }
//
//
//    // MARK: - Sign Out
//    func signOut() async {
//        try? await supabase.auth.signOut()
//        resetAuthState()
//    }
//
//    // MARK: - Current User
//    func currentUserId() async -> UUID? {
//        try? await supabase.auth.session.user.id
//    }
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
