import SwiftUI
import Combine

class StaffProfileViewModel: ObservableObject {
    
    let staff: Staff
    private let staffService = StaffService() // Assuming StaffService handles update logic
    
    // MARK: - Editable Fields
    @Published var fullName: String
    @Published var phone: String
    @Published var designation: String 
    @Published var departmentId: String
    @Published var city: String 
    @Published var email: String
    
    // Address (Mock/Local)
    @Published var country: String = "United Kingdom"
    @AppStorage("staff_city") var storedCity: String = "Leeds" 
    
    // MARK: - View State
    @Published var isEditingPersonal: Bool = false
    @Published var isEditingAddress: Bool = false
    @Published var isEditingRole: Bool = false // Logic for Admin editing role/dept
    
    // MARK: - Options
    let departments: [(id: String, name: String)] = [
        ("general", "General Medicine"),
        ("cardiology", "Cardiology"),
        ("neurology", "Neurology"),
        ("neurosurgery", "Neurosurgery"),
        ("orthopedics", "Orthopedics"),
        ("physiotherapy", "Physiotherapy"),
        ("sports_medicine", "Sports Medicine"),
        ("pediatrics", "Pediatrics"),
        ("neonatology", "Neonatology"),
        ("gynecology", "Gynecology"),
        ("obstetrics", "Obstetrics"),
        ("ent", "ENT (Ear, Nose & Throat)"),
        ("ophthalmology", "Ophthalmology"),
        ("psychiatry", "Psychiatry"),
        ("psychology", "Psychology"),
        ("dermatology", "Dermatology"),
        ("endocrinology", "Endocrinology"),
        ("radiology", "Radiology"),
        ("pathology", "Pathology"),
        ("laboratory", "Laboratory Medicine"),
        ("gastroenterology", "Gastroenterology"),
        ("pulmonology", "Pulmonology"),
        ("nephrology", "Nephrology"),
        ("urology", "Urology"),
        ("general_surgery", "General Surgery"),
        ("cardiac_surgery", "Cardiac Surgery"),
        ("plastic_surgery", "Plastic Surgery"),
        ("emergency", "Emergency Medicine"),
        ("critical_care", "Critical Care / ICU")
    ]
    
    init(staff: Staff) {
        self.staff = staff
        self.fullName = staff.fullName
        self.phone = staff.phone ?? ""
        self.email = staff.email
        self.designation = staff.designation ?? "Doctor"
        self.departmentId = staff.departmentId ?? "general"
        
        self.city = "Leeds" 
    }
    
    var role: String {
        return designation.isEmpty ? "Doctor" : designation
    }
    
    var departmentName: String {
        departments.first(where: { $0.id == departmentId })?.name ?? departmentId.capitalized
    }
    
    var locationString: String {
        "\(city), \(country)"
    }
    
    // MARK: - Actions
    
    func savePersonalInformation() async {
        do {
            try await staffService.updateStaffPersonalDetails(
                id: staff.id,
                fullName: fullName,
                phone: phone
            )
            
            await MainActor.run {
                withAnimation {
                    self.isEditingPersonal = false
                }
            }
        } catch {
            print("Error updating staff: \(error)")
        }
    }
    
    func saveRoleAndDepartment() async {
        do {
            try await staffService.updateStaffRoleAndDepartment(
                id: staff.id,
                role: designation,
                departmentId: departmentId
            )
            
            await MainActor.run {
                withAnimation {
                    self.isEditingRole = false
                }
            }
        } catch {
            print("Error updating staff role/dept: \(error)")
        }
    }
    
    func saveAddress() {
        // Mock save
        withAnimation {
            isEditingAddress = false
        }
    }
}
