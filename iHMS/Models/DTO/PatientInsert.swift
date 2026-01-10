//
//  PatientInsert.swift
//  iHMS
//
//  Created by Hargun Singh on 05/01/26.
//

import Foundation

struct PatientInsert: Encodable {
    let id: UUID
    let full_name: String
    let email: String
    let phone_number: String?
    let date_of_birth: Date?
    let gender: String?
    let blood_group: String?
}
struct PatientUpdateDTO: Encodable {
    let fullName: String
    let dateOfBirth: String?
    let gender: String?
    let phoneNumber: String?
    let email: String?
    let bloodGroup: String?
    let allergies: [String]?
    let currentMedications: [String]?
    let medicalHistory: String?
    let admissionStatus: String?
    let admissionDate: String?
    let dischargeDate: String?
    let assignedDoctorId: String?
    let emergencyContact: String?
    let emergencyContactRelation: String?
    let medicalRecordNumber: String?
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case dateOfBirth = "date_of_birth"
        case gender
        case phoneNumber = "phone_number"
        case email
        case bloodGroup = "blood_group"
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
