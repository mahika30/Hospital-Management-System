import Foundation
import SwiftUI

enum AdmissionStatus: String, Codable, CaseIterable {
    case admitted = "Admitted"
    case outpatient = "Outpatient"
    case discharged = "Discharged"
    case emergency = "Emergency"
    
    var color: Color {
        switch self {
        case .admitted: return .green
        case .outpatient: return .blue
        case .discharged: return .gray
        case .emergency: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .admitted: return "bed.double.fill"
        case .outpatient: return "figure.walk"
        case .discharged: return "checkmark.circle.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        }
    }
}

struct Patient: Identifiable, Codable {

    let id: UUID
    let fullName: String
    let email: String?
    let phoneNumber: String?
    let dateOfBirth: String?
    let gender: String?
    let createdAt: String?
    let bloodGroup: String?
    
    // Patient Records Extensions
    var allergies: [String]?
    var currentMedications: [String]?
    var medicalHistory: String?
    var admissionStatus: String?
    var admissionDate: String?
    var dischargeDate: String?
    var assignedDoctorId: UUID?
    var emergencyContact: String?
    var emergencyContactRelation: String?
    var medicalRecordNumber: String?
    var address: String?
    
    // Computed properties
    var createdDate: Date? {
        guard let dateString = createdAt else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: dateString) ?? ISO8601DateFormatter().date(from: dateString)
    }
    
    var age: Int {
        guard let dobString = dateOfBirth else { return 0 }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        if let dob = formatter.date(from: dobString) {
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: dob, to: Date())
            return ageComponents.year ?? 0
        }
        return 0
    }
    
    var initials: String {
        let components = fullName.split(separator: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else if let first = components.first {
            return String(first.prefix(2)).uppercased()
        }
        return "??"
    }
    
    var fullSearchText: String {
        let emailText = email ?? ""
        let addressText = address ?? ""
        let medicalHistoryText = medicalHistory ?? ""
        let allergiesText = allergies?.joined(separator: " ") ?? ""
        let mrnText = medicalRecordNumber ?? ""
        
        return "\(fullName) \(mrnText) \(phoneNumber ?? "") \(emailText) \(addressText) \(bloodGroup ?? "") \(allergiesText) \(medicalHistoryText)"
            .lowercased()
    }

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case email
        case phoneNumber = "phone_number"
        case dateOfBirth = "date_of_birth"
        case gender
        case bloodGroup = "blood_group"
        case createdAt = "created_at"
        case allergies
        case currentMedications = "current_medications"
        case medicalHistory = "medical_history"
        case admissionStatus = "admission_status"
        case admissionDate = "admission_date"
        case dischargeDate = "discharge_date"
        case assignedDoctorId = "assigned_doctor_id"
        case emergencyContact = "emergency_contact"
        case emergencyContactRelation = "emergency_contact_relation"
        case medicalRecordNumber = "medical_record_number"
        case address
    }
}
