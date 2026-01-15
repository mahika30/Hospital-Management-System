//
//  PatientService.swift
//  iHMS
//
//  Created by Hargun Singh on 05/01/26.
//

import Foundation
import Foundation
import Supabase

final class PatientService {

    private let client = SupabaseManager.shared.client
    
    func createPatient(
        id: UUID,
        fullName: String,
        email: String,
        phoneNumber: String?,
        dateOfBirth: Date?,
        gender: Gender?
    ) async throws {

        let patient = PatientInsert(
            id: id,
            full_name: fullName,
            email: email,
            phone_number: phoneNumber,
            date_of_birth: dateOfBirth,
            gender: gender?.rawValue,
            blood_group: nil
        )

        try await client
            .from("patients")
            .insert(patient)
            .execute()
    }

    func fetchPatient(id: UUID) async throws -> Patient? {

        let patients: [Patient] = try await client
            .from("patients")
            .select()
            .eq("id", value: id)
            .limit(1)
            .execute()
            .value

        return patients.first
    }
    
    func updatePatient(
        id: UUID,
        fullName: String,
        dateOfBirth: String?,
        gender: String?,
        phoneNumber: String?,
        email: String?,
        bloodGroup: String?,
        allergies: [String]?,
        currentMedications: [String]?,
        medicalHistory: String?,
        admissionStatus: String?,
        admissionDate: String?,
        dischargeDate: String?,
        assignedDoctorId: String?,
        emergencyContact: String?,
        emergencyContactRelation: String?,
        medicalRecordNumber: String?,
        address: String?
    ) async throws {

        let update = PatientUpdateDTO(
            fullName: fullName,
            dateOfBirth: dateOfBirth,
            gender: gender,
            phoneNumber: phoneNumber,
            email: email,
            bloodGroup: bloodGroup,
            allergies: allergies,
            currentMedications: currentMedications,
            medicalHistory: medicalHistory,
            admissionStatus: admissionStatus,
            admissionDate: admissionDate,
            dischargeDate: dischargeDate,
            assignedDoctorId: assignedDoctorId,
            emergencyContact: emergencyContact,
            emergencyContactRelation: emergencyContactRelation,
            medicalRecordNumber: medicalRecordNumber,
            address: address
        )

        try await SupabaseManager.shared.client
            .from("patients")
            .update(update)
            .eq("id", value: id.uuidString)
            .execute()
    }


    func fetchTotalPatients() async throws -> Int {
        let count = try await client
            .from("patients")
            .select("*", head: true, count: .exact)
            .execute()
            .count
        
        return count ?? 0
    }
    
    func fetchPatientsCount(from startDate: Date, to endDate: Date) async throws -> Int {
        let isoStart = ISO8601DateFormatter().string(from: startDate)
        let isoEnd = ISO8601DateFormatter().string(from: endDate)
        
        let count = try await client
            .from("patients")
            .select("*", head: true, count: .exact)
            .gte("created_at", value: isoStart)
            .lte("created_at", value: isoEnd)
            .execute()
            .count
        
        return count ?? 0
    }
    func fetchPatients(from startDate: Date, to endDate: Date) async throws -> [Patient] {
        let isoStart = ISO8601DateFormatter().string(from: startDate)
        let isoEnd = ISO8601DateFormatter().string(from: endDate)
        
        let patients: [Patient] = try await client
            .from("patients")
            .select()
            .gte("created_at", value: isoStart)
            .lte("created_at", value: isoEnd)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return patients
    }
}
