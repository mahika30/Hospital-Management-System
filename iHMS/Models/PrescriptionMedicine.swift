//
//  PrescriptionMedicine.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation

struct PrescriptionMedicine: Identifiable, Codable, Hashable {
    let id: UUID
    let prescriptionId: UUID
    var medicineName: String
    var dosage: String
    var frequency: String
    var duration: String
    var instructions: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case prescriptionId = "prescription_id"
        case medicineName = "medicine_name"
        case dosage
        case frequency
        case duration
        case instructions
        case createdAt = "created_at"
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PrescriptionMedicine, rhs: PrescriptionMedicine) -> Bool {
        lhs.id == rhs.id
    }
}
