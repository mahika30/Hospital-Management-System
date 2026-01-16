//
//  Prescription.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation

struct Prescription: Identifiable, Codable, Hashable {
    let id: UUID
    let appointmentId: UUID
    let patientId: UUID
    let staffId: UUID
    let prescriptionDate: String
    var diagnosis: String?
    var notes: String?
    var followUpDate: String?
    var followUpNotes: String?
    let createdAt: String?
    let updatedAt: String?
    
    // Relations
    var patient: Patient?
    var staff: Staff?
    var medicines: [PrescriptionMedicine]?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case patientId = "patient_id"
        case staffId = "staff_id"
        case prescriptionDate = "prescription_date"
        case diagnosis
        case notes
        case followUpDate = "follow_up_date"
        case followUpNotes = "follow_up_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case patient
        case staff
        case medicines = "prescription_medicines"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: Prescription, rhs: Prescription) -> Bool {
        lhs.id == rhs.id
    }
}
