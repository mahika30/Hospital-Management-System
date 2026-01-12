//
//  AppointmentService.swift
//  iHMS
//
//  Created by Hargun Singh on 08/01/26.
//

import Foundation
import Supabase
final class AppointmentService {

    func fetchAppointments(for patientId: UUID) async throws -> [Appointment] {

        let appointments: [Appointment] = try await SupabaseManager.shared.client
            .from("appointments")
            .select("""
                id,
                patient_id,
                staff_id,
                time_slot_id,
                appointment_date,
                status,
                created_at,
                updated_at,

                staff (
                    id,
                    full_name,
                    email,
                    department_id,
                    designation,
                    phone,
                    created_at,
                    specialization,
                    slot_capacity,
                    profile_image,
                    is_active
                ),

                time_slots (
                    id,
                    staff_id,
                    slot_date,
                    start_time,
                    end_time,
                    is_available,
                    current_bookings,
                    max_capacity,
                    is_running_late,
                    delay_minutes,
                    created_at,
                    updated_at
                )
            """)
            .eq("patient_id", value: patientId.uuidString)
            .order("appointment_date", ascending: true)
            .execute()
            .value

        return appointments
    }
    func fetchTotalAppointments() async throws -> Int {
        let count = try await SupabaseManager.shared.client
            .from("appointments")
            .select("*", head: true, count: .exact)
            .execute()
            .count
        
        return count ?? 0
    }
    
    func fetchAppointmentsCount(from startDate: Date, to endDate: Date) async throws -> Int {
        let isoStart = ISO8601DateFormatter().string(from: startDate)
        let isoEnd = ISO8601DateFormatter().string(from: endDate)
        
        let count = try await SupabaseManager.shared.client
            .from("appointments")
            .select("*", head: true, count: .exact)
            .gte("created_at", value: isoStart)
            .lte("created_at", value: isoEnd)
            .execute()
            .count
        
        return count ?? 0
    }
}

extension AppointmentService {

    func createAppointment(
        patientId: UUID,
        staffId: UUID,
        timeSlotId: UUID,
        appointmentDate: Date
    ) async throws {

        struct InsertAppointment: Encodable {
            let patient_id: UUID
            let staff_id: UUID
            let time_slot_id: UUID
            let appointment_date: Date
            let status: String
        }

        let payload = InsertAppointment(
            patient_id: patientId,
            staff_id: staffId,
            time_slot_id: timeSlotId,
            appointment_date: appointmentDate,
            status: "scheduled"
        )

        try await SupabaseManager.shared.client
            .from("appointments")
            .insert(payload)
            .execute()
    }
}
