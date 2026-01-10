//
//  AvailabilityViewModel.swift
//  iHMS
//
//  Created on 08/01/2026.
//

import Foundation
import SwiftUI
import Supabase

@Observable
class AvailabilityViewModel {

    // MARK: - State
    var staff: Staff
    var isLoading = false
    var errorMessage: String?

    var selectedDate: Date = Date()
    var timeSlots: [TimeSlot] = []

    // MARK: - Slot Grouping

    var morningSlots: [TimeSlot] {
        timeSlots.filter { $0.hour >= 6 && $0.hour < 12 }
    }

    var afternoonSlots: [TimeSlot] {
        timeSlots.filter { $0.hour >= 12 && $0.hour < 17 }
    }

    var eveningSlots: [TimeSlot] {
        timeSlots.filter { $0.hour >= 17 && $0.hour < 22 }
    }

    var selectedDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    private let supabase = SupabaseManager.shared.client

    init(staff: Staff) {
        self.staff = staff
    }

    // MARK: - Helpers

    private func formatDateForQuery(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func parseDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }

    // MARK: - Load Slots

    func loadTimeSlots() async {
        isLoading = true
        errorMessage = nil

        let dateString = formatDateForQuery(selectedDate)
        print("🔍 Loading slots for \(dateString)")

        do {
            guard let staffId = try? await supabase.auth.session.user.id else {
                errorMessage = "User not authenticated"
                isLoading = false
                return
            }

            await autoGenerateSlotsIfNeeded(staffId: staffId)

            let response: [TimeSlot] = try await supabase
                .from("time_slots")
                .select()
                .eq("staff_id", value: staffId.uuidString)
                .eq("slot_date", value: dateString)
                .order("start_time")
                .execute()
                .value

            timeSlots = response
            print("✅ Loaded \(response.count) slots")

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to load slots:", error)
        }

        isLoading = false
    }

    // MARK: - Auto Slot Generation (FIXED)

    private func autoGenerateSlotsIfNeeded(staffId: UUID) async {
        do {
            let response: [TimeSlot] = try await supabase
                .from("time_slots")
                .select()
                .eq("staff_id", value: staffId.uuidString)
                .order("slot_date", ascending: false)
                .limit(1)
                .execute()
                .value

            let today = Date()

            if let lastSlot = response.first,
               let lastSlotDate = parseDate(lastSlot.slotDate) {

                let daysDifference = Calendar.current.dateComponents(
                    [.day],
                    from: today,
                    to: lastSlotDate
                ).day ?? 0

                if daysDifference < 7 {
                    let startDate = Calendar.current.date(
                        byAdding: .day,
                        value: 1,
                        to: lastSlotDate
                    ) ?? today

                    print("⚠️ Low slots, generating more…")
                    await enableWeekdays(startDate: startDate, weeks: 2)
                }

            } else {
                print("⚠️ No slots found, generating initial set")
                await enableWeekdays(startDate: today, weeks: 2)
            }

        } catch {
            print("❌ Auto-generation failed:", error)
        }
    }

    // MARK: - Slot Actions

    func toggleSlot(_ slot: TimeSlot, isAvailable: Bool) async {
        struct Payload: Encodable { let is_available: Bool }

        do {
            try await supabase
                .from("time_slots")
                .update(Payload(is_available: isAvailable))
                .eq("id", value: slot.id.uuidString)
                .execute()

            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func markRunningLate(_ slot: TimeSlot, delay: Int) async {
        struct Payload: Encodable {
            let is_running_late: Bool
            let delay_minutes: Int
        }

        do {
            try await supabase
                .from("time_slots")
                .update(Payload(is_running_late: true, delay_minutes: delay))
                .eq("id", value: slot.id.uuidString)
                .execute()

            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func clearRunningLate(_ slot: TimeSlot) async {
        struct Payload: Encodable {
            let is_running_late: Bool
            let delay_minutes: Int
        }

        do {
            try await supabase
                .from("time_slots")
                .update(Payload(is_running_late: false, delay_minutes: 0))
                .eq("id", value: slot.id.uuidString)
                .execute()

            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateCapacity(_ slot: TimeSlot, capacity: Int) async {
        struct Payload: Encodable { let max_capacity: Int }

        do {
            try await supabase
                .from("time_slots")
                .update(Payload(max_capacity: capacity))
                .eq("id", value: slot.id.uuidString)
                .execute()

            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - NEW: Delay Adjuster
    
    func adjustDelay(_ slot: TimeSlot, by minutes: Int) async {
        let newDelay = max(0, slot.delayMinutes + minutes)
        
        struct Payload: Encodable {
            let delay_minutes: Int
            let is_running_late: Bool
        }
        
        do {
            try await supabase
                .from("time_slots")
                .update(Payload(delay_minutes: newDelay, is_running_late: newDelay > 0))
                .eq("id", value: slot.id.uuidString)
                .execute()
            
            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - NEW: Disable All Slots
    
    func disableAllSlots() async {
        struct Payload: Encodable { let is_available: Bool }
        
        do {
            let dateString = formatDateForQuery(selectedDate)
            guard let staffId = try? await supabase.auth.session.user.id else { return }
            
            try await supabase
                .from("time_slots")
                .update(Payload(is_available: false))
                .eq("staff_id", value: staffId.uuidString)
                .eq("slot_date", value: dateString)
                .execute()
            
            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Slot Generation

    func generateSlotsForDate() async {
        guard let staffId = try? await supabase.auth.session.user.id else { return }

        let dateString = formatDateForQuery(selectedDate)

        do {
            try await supabase.rpc(
                "generate_default_slots_for_date",
                params: [
                    "p_staff_id": staffId.uuidString,
                    "p_date": dateString,
                    "p_default_capacity": "5"
                ]
            ).execute()

            await loadTimeSlots()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func enableWeekdays(startDate: Date, weeks: Int) async {
        await generateSlotsForDateRange(startDate: startDate, weeks: weeks, weekdaysOnly: true)
    }
    
    // MARK: - NEW: Enable Weekend
    
    func enableWeekend(startDate: Date, weeks: Int) async {
        await generateSlotsForDateRange(startDate: startDate, weeks: weeks, weekdaysOnly: false, weekendOnly: true)
    }

    private func generateSlotsForDateRange(
        startDate: Date,
        weeks: Int,
        weekdaysOnly: Bool,
        weekendOnly: Bool = false
    ) async {

        guard let staffId = try? await supabase.auth.session.user.id else { return }

        let calendar = Calendar.current
        let totalDays = weeks * 7

        for offset in 0..<totalDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: startDate) else { continue }

            let weekday = calendar.component(.weekday, from: date)
            
            if weekdaysOnly && (weekday == 1 || weekday == 7) { continue }
            if weekendOnly && (weekday != 1 && weekday != 7) { continue }

            let dateString = formatDateForQuery(date)

            try? await supabase.rpc(
                "generate_default_slots_for_date",
                params: [
                    "p_staff_id": staffId.uuidString,
                    "p_date": dateString,
                    "p_default_capacity": "5"
                ]
            ).execute()
        }

        await loadTimeSlots()
    }
}
