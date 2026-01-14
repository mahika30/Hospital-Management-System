//
//  CompletedAppointmentsViewModel.swift
//  iHMS
//
//  Created on 12/01/2026.
//

import Foundation
import Combine
import Supabase

@MainActor
class CompletedAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let staffId: UUID
    
    init(staffId: UUID) {
        self.staffId = staffId
    }
    
    func loadCompletedAppointments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let appointments: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select("""
                    *,
                    patients!inner(
                        id,
                        full_name,
                        email,
                        gender,
                        date_of_birth,
                        blood_group,
                        phone_number
                    ),
                    time_slots(
                        id,
                        start_time,
                        end_time
                    )
                """)
                .eq("staff_id", value: staffId.uuidString)
                .eq("status", value: "completed")
                .order("appointment_date", ascending: false)
                .execute()
                .value
            
            print("✅ Loaded \(appointments.count) completed appointments")
            for apt in appointments {
                print("   - Patient: \(apt.patient?.fullName ?? "nil")")
            }
            
            self.appointments = appointments
        } catch {
            errorMessage = "Failed to load completed appointments: \(error.localizedDescription)"
            print("❌ Error loading completed appointments: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshAppointments() async {
        await loadCompletedAppointments()
    }
}
