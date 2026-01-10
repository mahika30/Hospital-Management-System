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
    
    /// Creates default time slots for a staff member for a specific date
    /// Creates 1-hour slots from 9 AM to 5 PM
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
        
        // Create 1-hour slots from 9 AM to 5 PM (9:00-10:00, 10:00-11:00, ..., 16:00-17:00)
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
        
        // Insert all slots
        try await supabase
            .from("time_slots")
            .insert(slots)
            .execute()
        
        print("✅ Created \(slots.count) default time slots for staff \(staffId) on \(dateString)")
    }
    
    /// Generates slots for a date range
    func createTimeSlotsForDateRange(staffId: UUID, startDate: Date, endDate: Date, capacity: Int = 5, weekdaysOnly: Bool = false) async throws {
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= endDate {
            let weekday = calendar.component(.weekday, from: currentDate)
            
            // Skip weekends if weekdaysOnly is true
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
}
