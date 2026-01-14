//
//  EditPrescriptionViewModel.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
class EditPrescriptionViewModel: ObservableObject {
    @Published var prescription: Prescription
    @Published var diagnosis: String
    @Published var notes: String
    @Published var medicines: [MedicineInput] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    init(prescription: Prescription) {
        self.prescription = prescription
        self.diagnosis = prescription.diagnosis ?? ""
        self.notes = prescription.notes ?? ""
        
        // Convert existing medicines to MedicineInput
        if let existingMedicines = prescription.medicines {
            self.medicines = existingMedicines.map { medicine in
                MedicineInput(
                    name: medicine.medicineName,
                    dosage: medicine.dosage,
                    frequency: medicine.frequency,
                    duration: medicine.duration,
                    instructions: medicine.instructions ?? ""
                )
            }
        }
    }
    
    func addMedicine(_ medicine: MedicineInput) {
        medicines.append(medicine)
    }
    
    func removeMedicine(at index: Int) {
        medicines.remove(at: index)
    }
    
    func updatePrescription() async -> Bool {
        guard !medicines.isEmpty else {
            errorMessage = "Please add at least one medicine"
            return false
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 1. Update prescription
            struct PrescriptionUpdate: Encodable {
                let diagnosis: String?
                let notes: String?
                let updated_at: String
            }
            
            let now = ISO8601DateFormatter().string(from: Date())
            
            let updateData = PrescriptionUpdate(
                diagnosis: diagnosis.isEmpty ? nil : diagnosis,
                notes: notes.isEmpty ? nil : notes,
                updated_at: now
            )
            
            try await SupabaseManager.shared.client
                .from("prescriptions")
                .update(updateData)
                .eq("id", value: prescription.id.uuidString)
                .execute()
            
            // 2. Delete existing medicines
            try await SupabaseManager.shared.client
                .from("prescription_medicines")
                .delete()
                .eq("prescription_id", value: prescription.id.uuidString)
                .execute()
            
            // 3. Insert new medicines
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
                    prescription_id: prescription.id.uuidString,
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
            
            successMessage = "Prescription updated successfully"
            isLoading = false
            return true
            
        } catch {
            errorMessage = "Failed to update prescription: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
