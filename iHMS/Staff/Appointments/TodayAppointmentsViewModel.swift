//
//  TodayAppointmentsViewModel.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import SwiftUI
import Supabase
import Combine

@MainActor
class TodayAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    let staffId: UUID
    
    init(staffId: UUID) {
        self.staffId = staffId
    }
    
    func loadTodayAppointments() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)
            let tomorrowString = dateFormatter.string(from: tomorrow)
            
            print("🔍 Loading appointments for staff: \(staffId)")
            print("🔍 Today: \(todayString)")
            print("🔍 Tomorrow: \(tomorrowString)")
            
            let response: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select("""
                    *,
                    patients!inner(
                        id,
                        full_name,
                        date_of_birth,
                        gender,
                        phone_number,
                        blood_group,
                        allergies,
                        current_medications,
                        medical_history
                    ),
                    time_slots(
                        id,
                        start_time,
                        end_time
                    )
                """)
                .eq("staff_id", value: staffId.uuidString)
                .gte("appointment_date", value: todayString)
                .lt("appointment_date", value: tomorrowString)
                .order("appointment_date", ascending: true)
                .execute()
                .value
            
            print("✅ Found \(response.count) appointments")
            for (index, apt) in response.enumerated() {
                print("   Appointment \(index + 1): \(apt.id)")
                print("   Has patient: \(apt.patient != nil)")
                if let patient = apt.patient {
                    print("   Patient: \(patient.fullName)")
                }
            }
            
            // Sort appointments by time slot start time
            appointments = response.sorted { apt1, apt2 in
                guard let slot1 = apt1.timeSlot, let slot2 = apt2.timeSlot else {
                    return false
                }
                return slot1.startTime < slot2.startTime
            }
        } catch {
            print("❌ Error: \(error)")
            errorMessage = "Failed to load appointments: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func updateAppointmentStatus(appointmentId: UUID, status: String) async {
        do {
            struct StatusUpdate: Encodable {
                let appointment_status: String
            }
            
            try await SupabaseManager.shared.client
                .from("appointments")
                .update(StatusUpdate(appointment_status: status))
                .eq("id", value: appointmentId.uuidString)
                .execute()
            
            await loadTodayAppointments()
        } catch {
            errorMessage = "Failed to update status: \(error.localizedDescription)"
        }
    }
}
