//
//  PrescriptionsViewModel.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
class PrescriptionsViewModel: ObservableObject {
    @Published var prescriptions: [Prescription] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let patientId: UUID
    
    init(patientId: UUID) {
        self.patientId = patientId
    }
    
    func loadPrescriptions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            print("📋 [Patient] Loading prescriptions for patient: \(patientId)")
            let response: [Prescription] = try await SupabaseManager.shared.client
                .from("prescriptions")
                .select("""
                    *,
                    prescription_medicines(
                        id,
                        prescription_id,
                        medicine_name,
                        dosage,
                        frequency,
                        duration,
                        instructions
                    )
                """)
                .eq("patient_id", value: patientId.uuidString)
                .order("prescription_date", ascending: false)
                .execute()
                .value
            
            prescriptions = response
            print("✅ [Patient] Loaded \(prescriptions.count) prescriptions")
        } catch {
            print("❌ [Patient] Error loading prescriptions: \(error)")
            errorMessage = "Failed to load prescriptions: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
