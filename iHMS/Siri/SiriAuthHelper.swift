import Foundation
import AppIntents
import Supabase

struct IntentRoleGuard {
    
    enum Role: String {
        case patient
        case staff
        case admin
    }
    
    @MainActor
    static func validate(role requiredRole: Role) async throws -> UUID {
        
        let client = SupabaseManager.shared.client
        
        guard let session = try? await client.auth.session else {
            throw IntentError.message("Please log in to iHMS first.")
        }
        
        let userId = session.user.id
        struct ProfileRoleDTO: Decodable {
            let role: String
            let is_active: Bool
        }
        
        do {
            let profile: ProfileRoleDTO = try await client
                .from("profiles")
                .select("role, is_active")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            guard profile.is_active else {
                throw IntentError.message("Your account is inactive.")
            }
            
            guard profile.role == requiredRole.rawValue else {
                throw IntentError.message("I'm sorry, but you don't have permission to perform this action.")
            }
            
            return userId
            
        } catch {
            if let intentError = error as? IntentError {
                throw intentError
            }
            throw IntentError.message("I couldn't verify your permission level.")
        }
    }
}
