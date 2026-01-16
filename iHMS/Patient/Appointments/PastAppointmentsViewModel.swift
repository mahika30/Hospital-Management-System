//
//  PastAppointmentsViewModel.swift
//  iHMS
//
//  Created on 12/01/2026.
//

import Foundation
import Combine
import Supabase

@MainActor
class PastAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let patientId: UUID
    
    init(patientId: UUID) {
        self.patientId = patientId
    }
    
    func loadPastAppointments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let today = Date()
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withFullDate]
            
            let appointments: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select("""
                    *,
                    staff:staff_id (
                        id,
                        full_name,
                        email,
                        designation,
                        specialization
                    ),
                    time_slots:time_slot_id (*)
                """)
                .eq("patient_id", value: patientId.uuidString)
                .or("appointment_date.lt.\(dateFormatter.string(from: today)),status.eq.completed,status.eq.cancelled")
                .order("appointment_date", ascending: false)
                .execute()
                .value
            
            self.appointments = appointments
        } catch {
            errorMessage = "Failed to load past appointments: \(error.localizedDescription)"
            print("Error loading past appointments: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshAppointments() async {
        await loadPastAppointments()
    }
}
