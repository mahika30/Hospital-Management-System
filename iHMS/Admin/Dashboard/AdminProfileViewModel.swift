import SwiftUI
import Combine
import Supabase

class AdminProfileViewModel: ObservableObject {
    
    // MARK: - Local State (Synced with DB)
    @Published var firstName: String = ""
    @Published var lastName: String = ""
    @Published var phone: String = ""
    @Published var email: String = ""
    @Published var role: String = "Admin"
    
    // Address (Keeping AppStorage for now as 'profiles' might not have address fields defined in schema yet)
    @AppStorage("admin_dob") var dobTimestamp: Double = Date(timeIntervalSince1970: 946684800).timeIntervalSince1970
    @AppStorage("admin_country") var country: String = "United Kingdom"
    @AppStorage("admin_city") var city: String = "Leeds"
    @AppStorage("admin_postalCode") var postalCode: String = "LS1 1AZ"
    
    // MARK: - View State
    @Published var isEditingPersonal: Bool = false
    @Published var isEditingAddress: Bool = false
    @Published var isLoading = false
    
    private let supabase = SupabaseManager.shared.client
    
    var fullName: String {
        let name = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Admin" : name
    }
    
    var dateOfBirth: Date {
        get { Date(timeIntervalSince1970: dobTimestamp) }
        set { dobTimestamp = newValue.timeIntervalSince1970 }
    }
    
    var locationString: String {
        "\(city), \(country)"
    }
    
    init() {
        Task { await fetchProfile() }
    }
    
    @MainActor
    func fetchProfile() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let userId = try await supabase.auth.session.user.id
            
            // Define DTO matching 'profiles' table
            struct AdminProfileDTO: Decodable {
                let full_name: String?
                let email: String?
                let role: String?
            }
            
            let profile: AdminProfileDTO = try await supabase
                .from("profiles")
                .select("full_name, email, role")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            // Parse Full Name into First/Last
            if let fullName = profile.full_name {
                let components = fullName.components(separatedBy: " ")
                if !components.isEmpty {
                    self.firstName = components.first ?? ""
                    self.lastName = components.dropFirst().joined(separator: " ")
                }
            }
            self.email = profile.email ?? ""
            self.role = profile.role?.capitalized ?? "Admin"
            
            // If phone is in profiles, fetch it. Assuming it's not based on AuthViewModel, keeping empty or from AppStorage if needed.
            // For now, phone is blank or default.
            
        } catch {
            print("Error fetching admin profile: \(error)")
        }
    }
    
    @MainActor
    func savePersonalInformation() {
        Task {
            do {
                let userId = try await supabase.auth.session.user.id
                let newFullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                
                // Update Supabase
                struct UpdatePayload: Encodable {
                    let full_name: String
                }
                
                try await supabase
                    .from("profiles")
                    .update(UpdatePayload(full_name: newFullName))
                    .eq("id", value: userId.uuidString)
                    .execute()
                
                withAnimation {
                    self.isEditingPersonal = false
                }
                
                print("✅ Admin profile updated successfully")
                
            } catch {
                print("❌ Error saving admin profile: \(error)")
            }
        }
    }
    
    func saveAddress() {
        // AppStorage updates automatically, just close edit mode
        withAnimation {
            isEditingAddress = false
        }
    }
    
    func togglePersonalEdit() {
        withAnimation {
            isEditingPersonal.toggle()
        }
    }
    
    func toggleAddressEdit() {
        withAnimation {
            isEditingAddress.toggle()
        }
    }
}
