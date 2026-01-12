//
//  StaffService.swift
//  iHMS
//
//  Created by Hargun Singh on 07/01/26.
//

import Foundation
import Supabase

final class StaffService {

    private let supabase = SupabaseManager.shared.client

    func fetchStaff() async throws -> [Staff] {

        let response: [Staff] = try await supabase
            .from("staff")
            .select("""
                id,
                full_name,
                email,
                department_id,
                designation,
                phone,
                created_at
            """)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }
    
    func createDefaultTimeSlotsForDate(staffId: UUID, date: Date, capacity: Int = 5) async throws {
        struct TimeSlotInsert: Encodable {
            let staff_id: String
            let slot_date: String
            let start_time: String
            let end_time: String
            let is_available: Bool
            let current_bookings: Int
            let max_capacity: Int
        }
        
        let dateString = formatDateForInsert(date)
        var slots: [TimeSlotInsert] = []
        
        for hour in 9...16 {
            let startTime = String(format: "%02d:00:00", hour)
            let endTime = String(format: "%02d:00:00", hour + 1)
            
            slots.append(TimeSlotInsert(
                staff_id: staffId.uuidString,
                slot_date: dateString,
                start_time: startTime,
                end_time: endTime,
                is_available: true,
                current_bookings: 0,
                max_capacity: capacity
            ))
        }
        
        try await supabase
            .from("time_slots")
            .insert(slots)
            .execute()
        
        print(" Created \(slots.count) default time slots for staff \(staffId) on \(dateString)")
    }
    
    func createTimeSlotsForDateRange(staffId: UUID, startDate: Date, endDate: Date, capacity: Int = 5, weekdaysOnly: Bool = false) async throws {
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            if weekdaysOnly && (weekday == 1 || weekday == 7) {
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
                continue
            }
            
            try await createDefaultTimeSlotsForDate(staffId: staffId, date: currentDate, capacity: capacity)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
    }
    
    private func formatDateForInsert(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    func updateStaffPersonalDetails(id: UUID, fullName: String, phone: String) async throws {
        struct UpdatePayload: Encodable {
            let full_name: String
            let phone: String
        }
        
        let payload = UpdatePayload(full_name: fullName, phone: phone)
        
        try await supabase
            .from("staff")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func updateStaffRoleAndDepartment(id: UUID, role: String, departmentId: String) async throws {
        struct UpdatePayload: Encodable {
            let designation: String
            let department_id: String
        }
        
        let payload = UpdatePayload(designation: role, department_id: departmentId)
        
        try await supabase
            .from("staff")
            .update(payload)
            .eq("id", value: id.uuidString)
            .execute()
    }
}
