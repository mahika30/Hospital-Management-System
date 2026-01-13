//
//  CreatePrescriptionViewModel.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import SwiftUI
import Supabase
import Combine

struct MedicineInput: Identifiable {
    let id = UUID()
    var name: String
    var dosage: String
    var frequency: String
    var duration: String
    var instructions: String
}

@MainActor
class CreatePrescriptionViewModel: ObservableObject {
    @Published var diagnosis: String = ""
    @Published var notes: String = ""
    @Published var medicines: [MedicineInput] = []
    @Published var followUpDate: Date?
    @Published var followUpNotes: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    let patient: Patient
    let appointment: Appointment
    let staffId: UUID
    
    init(patient: Patient, appointment: Appointment, staffId: UUID) {
        self.patient = patient
        self.appointment = appointment
        self.staffId = staffId
    }
    
    func addMedicine(_ medicine: MedicineInput) {
        medicines.append(medicine)
    }
    
    func removeMedicine(at index: Int) {
        medicines.remove(at: index)
    }
    
    func savePrescription() async -> Bool {
        guard !medicines.isEmpty else {
            errorMessage = "Please add at least one medicine"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Check if prescription already exists
            struct PrescriptionIdResponse: Decodable {
                let id: UUID
            }
            
            let existingResponse: [PrescriptionIdResponse] = try await SupabaseManager.shared.client
                .from("prescriptions")
                .select("id")
                .eq("appointment_id", value: appointment.id.uuidString)
                .execute()
                .value
            
            if let existing = existingResponse.first {
                // Update existing prescription
                print("✅ Found existing prescription: \(existing.id)")
                return await updatePrescription(prescriptionId: existing.id)
            } else {
                // Create new prescription
                print("✅ No existing prescription, creating new one")
                return await createNewPrescription()
            }
        } catch {
            print("❌ Error checking existing prescription: \(error)")
            errorMessage = "Failed to save prescription: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    private func createNewPrescription() async -> Bool {
        do {
            struct PrescriptionInsert: Encodable {
                let appointment_id: String
                let patient_id: String
                let staff_id: String
                let prescription_date: String
                let diagnosis: String?
                let notes: String?
                let follow_up_date: String?
                let follow_up_notes: String?
            }
            
            let today = Date()
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            
            let prescriptionData = PrescriptionInsert(
                appointment_id: appointment.id.uuidString,
                patient_id: patient.id.uuidString,
                staff_id: staffId.uuidString,
                prescription_date: dateFormatter.string(from: today),
                diagnosis: diagnosis.isEmpty ? nil : diagnosis,
                notes: notes.isEmpty ? nil : notes,
                follow_up_date: followUpDate != nil ? dateFormatter.string(from: followUpDate!) : nil,
                follow_up_notes: followUpNotes.isEmpty ? nil : followUpNotes
            )
            
            // Insert prescription and get the inserted data back
            struct PrescriptionResponse: Decodable {
                let id: UUID
            }
            
            let response: [PrescriptionResponse] = try await SupabaseManager.shared.client
                .from("prescriptions")
                .insert(prescriptionData)
                .select("id")
                .execute()
                .value
            
            guard let prescriptionId = response.first?.id else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create prescription"])
            }
            
            print("✅ Prescription created with ID: \(prescriptionId)")
            
            // 2. Add medicines
            struct MedicineInsert: Encodable {
                let prescription_id: String
                let medicine_name: String
                let dosage: String
                let frequency: String
                let duration: String
                let instructions: String?
            }
            
            let medicinesData = medicines.map { medicine in
                MedicineInsert(
                    prescription_id: prescriptionId.uuidString,
                    medicine_name: medicine.name,
                    dosage: medicine.dosage,
                    frequency: medicine.frequency,
                    duration: medicine.duration,
                    instructions: medicine.instructions.isEmpty ? nil : medicine.instructions
                )
            }
            
            try await SupabaseManager.shared.client
                .from("prescription_medicines")
                .insert(medicinesData)
                .execute()
            
            print("✅ Prescription medicines saved: \(medicines.count) items")
            
            successMessage = "Prescription created successfully"
            isLoading = false
            return true
            
        } catch {
            print("❌ Error creating prescription: \(error)")
            print("   Error details: \(String(describing: error))")
            errorMessage = "Failed to create prescription. Please ensure database tables are created: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    private func updatePrescription(prescriptionId: UUID) async -> Bool {
        do {
            // Update prescription
            struct PrescriptionUpdate: Encodable {
                let diagnosis: String?
                let notes: String?
                let follow_up_date: String?
                let follow_up_notes: String?
            }
            
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            
            let updateData = PrescriptionUpdate(
                diagnosis: diagnosis.isEmpty ? nil : diagnosis,
                notes: notes.isEmpty ? nil : notes,
                follow_up_date: followUpDate != nil ? dateFormatter.string(from: followUpDate!) : nil,
                follow_up_notes: followUpNotes.isEmpty ? nil : followUpNotes
            )
            
            try await SupabaseManager.shared.client
                .from("prescriptions")
                .update(updateData)
                .eq("id", value: prescriptionId.uuidString)
                .execute()
            
            print("✅ Prescription updated: \(prescriptionId)")
            
            // Delete existing medicines
            try await SupabaseManager.shared.client
                .from("prescription_medicines")
                .delete()
                .eq("prescription_id", value: prescriptionId.uuidString)
                .execute()
            
            // Add new medicines
            struct MedicineInsert: Encodable {
                let prescription_id: String
                let medicine_name: String
                let dosage: String
                let frequency: String
                let duration: String
                let instructions: String?
            }
            
            let medicinesData = medicines.map { medicine in
                MedicineInsert(
                    prescription_id: prescriptionId.uuidString,
                    medicine_name: medicine.name,
                    dosage: medicine.dosage,
                    frequency: medicine.frequency,
                    duration: medicine.duration,
                    instructions: medicine.instructions.isEmpty ? nil : medicine.instructions
                )
            }
            
            try await SupabaseManager.shared.client
                .from("prescription_medicines")
                .insert(medicinesData)
                .execute()
            
            print("✅ Prescription medicines updated: \(medicines.count) items")
            
            successMessage = "Prescription updated successfully"
            isLoading = false
            return true
            
        } catch {
            print("❌ Error updating prescription: \(error)")
            errorMessage = "Failed to update prescription: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
