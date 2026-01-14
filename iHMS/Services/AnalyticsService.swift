//
//  AnalyticsService.swift
//  iHMS
//
//  Created by User on 12/01/2026.
//

import Foundation
import Supabase
class AnalyticsService {
    static let shared = AnalyticsService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    private func expectedBookingsPerDay(
        appointments: [AnalyticsAppointmentDTO]
    ) -> [String: Double] {

        var counts: [String: Int] = [:]
        var dayOccurrences: [String: Int] = [:]

        for appt in appointments {
            if let date = parseDate(appt.appointmentDate) {
                let day = date.formatted(.dateTime.weekday(.wide))
                counts[day, default: 0] += 1
                dayOccurrences[day, default: 0] += 1
            }
        }

        var expected: [String: Double] = [:]

        for (day, count) in counts {
            let occurrences = dayOccurrences[day] ?? 1
            expected[day] = Double(count) / Double(occurrences)
        }

        return expected
    }

    
    func predictStaffRequirementV2(
        appointments: [AnalyticsAppointmentDTO],
        slots: [AnalyticsTimeSlotDTO],
        lookAheadDays: Int = 7
    ) -> [String] {

        let expectedMap = expectedBookingsPerDay(appointments: appointments)
        let today = Date()

        var actualPerDate: [String: Int] = [:]

        for appt in appointments {
            actualPerDate[appt.appointmentDate, default: 0] += 1
        }

        var messages: [String] = []

        for (dateStr, expected) in expectedMap {
            guard let date = parseDate(dateStr) else { continue }

            let daysAhead = Calendar.current.dateComponents([.day], from: today, to: date).day ?? 0

            // Ignore far future
            if daysAhead > lookAheadDays { continue }

            let actual = actualPerDate[dateStr] ?? 0

            let ratio = Double(actual) / max(1.0, expected)

            if ratio > 1.2 {
                messages.append("⚠️ High demand expected on \(dateStr). Consider adding staff.")
            } else if ratio < 0.6 {
                messages.append("ℹ️ Lower-than-usual demand on \(dateStr). Monitor bookings.")
            }
        }

        return messages.isEmpty
            ? ["Staffing appears aligned with expected demand."]
            : messages.sorted()
    }


    
    /// Fetches necessary data for analytics computations
    func fetchAnalyticsData() async throws -> ([AnalyticsAppointmentDTO], [AnalyticsTimeSlotDTO], [AnalyticsStaffDTO]) {
        async let appointmentsQuery: [AnalyticsAppointmentDTO] = client
            .from("appointments")
            .select()
            .execute()
            .value
        
        async let timeSlotsQuery: [AnalyticsTimeSlotDTO] = client
            .from("time_slots")
            .select()
            .execute()
            .value
        
        async let staffQuery: [AnalyticsStaffDTO] = client
            .from("staff")
            .select()
            .execute()
            .value
        
        return try await (appointmentsQuery, timeSlotsQuery, staffQuery)
    }
    
    // MARK: - Computations
    
    /// Identifies the busiest day of the week based on appointment count
    func calculateBusiestDay(from appointments: [AnalyticsAppointmentDTO]) -> String {
        guard !appointments.isEmpty else { return "No Data" }
        
        var dayCounts: [String: Int] = [:]
        
        for appt in appointments {
            if let date = parseDate(appt.appointmentDate) {
                let dayName = date.formatted(.dateTime.weekday(.wide))
                dayCounts[dayName, default: 0] += 1
            }
        }
        
        return dayCounts.max(by: { $0.value < $1.value })?.key ?? "No Data"
    }
    
    /// Identifies the busiest time slot range
    func calculateBusiestTimeSlot(from slots: [AnalyticsTimeSlotDTO]) -> String {
        guard !slots.isEmpty else { return "No Data" }
        
        var slotCounts: [String: Int] = [:]
        
        for slot in slots {
            let key = "\(slot.startTime) - \(slot.endTime)"
            slotCounts[key, default: 0] += slot.currentBookings
        }
        
        if let maxSlot = slotCounts.max(by: { $0.value < $1.value }) {
            return "\(formatTime(maxSlot.key)) (Total: \(maxSlot.value))"
        }
        
        return "No Data"
    }
    
    /// Identifies staff with the most appointments
    func calculateMostOccupiedStaff(appointments: [AnalyticsAppointmentDTO], staffList: [AnalyticsStaffDTO]) -> String {
        guard !appointments.isEmpty else { return "No Data" }
        
        var staffCounts: [UUID: Int] = [:]
        
        for appt in appointments {
            staffCounts[appt.staffId, default: 0] += 1
        }
        
        guard let busiestStaffId = staffCounts.max(by: { $0.value < $1.value })?.key,
              let staffMember = staffList.first(where: { $0.id == busiestStaffId }) else {
            return "No Data"
        }
        
        let count = staffCounts[busiestStaffId] ?? 0
        return "\(staffMember.fullName) (\(count) appointments)"
    }
    
    /// Suggests best available slots personalized for a specific patient
    func suggestAppointmentSlots(for patientId: UUID, history: [AnalyticsAppointmentDTO], slots: [AnalyticsTimeSlotDTO], staff: [AnalyticsStaffDTO], limit: Int = 5) -> [String] {
        guard !slots.isEmpty else { return ["No slots available"] }
        
        // 1. Analyze Patient History
        let patientAppointments = history.filter { $0.patientId == patientId }
        
        // Find preferred doctor (most visited)
        var doctorVisits: [UUID: Int] = [:]
        var hourSum = 0
        var validTimeCount = 0
        
        for appt in patientAppointments {
            doctorVisits[appt.staffId, default: 0] += 1
            
            // Try to extract hour from time
            if let time = appt.appointmentTime, let hour = Int(time.split(separator: ":")[0]) {
                hourSum += hour
                validTimeCount += 1
            }
        }
        
        let preferredDoctorId = doctorVisits.max(by: { $0.value < $1.value })?.key
        let preferredHour = validTimeCount > 0 ? Double(hourSum) / Double(validTimeCount) : 10.0 // Default to 10 AM
        
        // 2. Filter & Score Future Slots
        let today = Date()
        
        let rankedSlots = slots.compactMap { slot -> (slot: AnalyticsTimeSlotDTO, score: Double)? in
            guard let date = parseDate(slot.slotDate), date >= today, slot.currentBookings < slot.maxCapacity else {
                return nil
            }
            
            var score = 0.0
            
            // Prefer Recent Dates (descending base score)
            let daysUntil = Calendar.current.dateComponents([.day], from: today, to: date).day ?? 0
            score += Double(max(0, 30 - daysUntil)) // Higher score for closer dates
            
            // Match Preferred Doctor (+50)
            if let favDoc = preferredDoctorId, slot.staffId == favDoc {
                score += 50.0
            }
            
            // Match Preferred Time (+20 for within 2 hours)
            if let slotHour = Int(slot.startTime.split(separator: ":")[0]) {
                let diff = abs(Double(slotHour) - preferredHour)
                if diff <= 2.0 {
                    score += 20.0
                }
            }
            
            return (slot, score)
        }
        .sorted { $0.score > $1.score } // Sort by highest score
        
        // 3. Format Output
        return rankedSlots.prefix(limit).map { item in
            let slot = item.slot
            let doctorName = staff.first(where: { $0.id == slot.staffId })?.fullName ?? "Unknown Doctor"
            let timeStr = formatTime("\(slot.startTime) - \(slot.endTime)")
            
            // Add context label if applicable
            var label = ""
            if let favDoc = preferredDoctorId, slot.staffId == favDoc {
                label = " (⭐ Your Doctor)"
            }
            
            return "\(slot.slotDate) @ \(timeStr) with \(doctorName)\(label)"
        }
    }
    
    /// Refined prediction of staff requirements
    func predictStaffRequirement(slots: [AnalyticsTimeSlotDTO]) -> [String] {
        guard !slots.isEmpty else { return ["Insufficient data"] }
        
        var dayUtilization: [String: (booked: Int, capacity: Int)] = [:]
        
        for slot in slots {
            let current = dayUtilization[slot.slotDate] ?? (0, 0)
            dayUtilization[slot.slotDate] = (current.booked + slot.currentBookings, current.capacity + slot.maxCapacity)
        }
        
        var suggestions: [String] = []
        for (date, stats) in dayUtilization {
            guard stats.capacity > 0 else { continue }
            let utilization = Double(stats.booked) / Double(stats.capacity)
            
            if utilization > 0.85 {
                suggestions.append("⚠️ High load on \(date) (\(Int(utilization * 100))%). Consider adding staff.")
            } else if utilization < 0.30 {
                suggestions.append("📉 Low load on \(date) (\(Int(utilization * 100))%). Consider reducing staff.")
            }
        }
        
        return suggestions.isEmpty ? ["Staffing levels appear adequate."] : suggestions.sorted()
    }
    func staffSuggestionsForHighDemandDays(
        appointments: [AnalyticsAppointmentDTO],
        staffList: [AnalyticsStaffDTO]
    ) -> [String: [AnalyticsStaffDTO]] {

        // Group appointments by weekday
        let groupedByDay = Dictionary(grouping: appointments) { appt in
            parseDate(appt.appointmentDate)?
                .formatted(.dateTime.weekday(.wide)) ?? "Unknown"
        }

        var result: [String: [AnalyticsStaffDTO]] = [:]

        for (day, dayAppointments) in groupedByDay {

            // Count appointments per staff for that weekday
            var staffCount: [UUID: Int] = [:]
            for appt in dayAppointments {
                staffCount[appt.staffId, default: 0] += 1
            }

            // Sort staff by workload
            let sortedStaff = staffCount
                .sorted { $0.value > $1.value }
                .compactMap { entry in
                    staffList.first { $0.id == entry.key }
                }

            if !sortedStaff.isEmpty {
                result[day] = sortedStaff
            }
        }

        return result
    }

    
    /// Refined patient load prediction
    func predictPatientLoad(appointments: [AnalyticsAppointmentDTO]) -> String {
        guard appointments.count > 5 else { return "Need more data for trend analysis" }
        
        var dailyCounts: [Date: Int] = [:]
        for appt in appointments {
            if let date = parseDate(appt.appointmentDate) {
                dailyCounts[date, default: 0] += 1
            }
        }
        
        let sortedDays = dailyCounts.keys.sorted()
        guard sortedDays.count >= 2 else { return "Stable (Insufficient daily spread)" }
        
        let midPoint = sortedDays.count / 2
        let firstHalf = sortedDays.prefix(midPoint)
        let secondHalf = sortedDays.suffix(from: midPoint)
        
        let avgFirst = Double(firstHalf.reduce(0) { $0 + dailyCounts[$1]! }) / Double(firstHalf.count)
        let avgSecond = Double(secondHalf.reduce(0) { $0 + dailyCounts[$1]! }) / Double(secondHalf.count)
        
        if avgSecond > avgFirst * 1.05 {
            return "📈 Increasing Trend (+5% growth). Prepare resources."
        } else if avgSecond < avgFirst * 0.95 {
            return "📉 Decreasing Trend. Monitor marketing."
        } else {
            return "➡️ Stable Trend."
        }
    }
    
    // MARK: - Helpers
    
    /// Robust Date Parsing
    private func parseDate(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        
        // Try fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) { return date }
        
        // Try standard ISO
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) { return date }
        
        // Try simple yyyy-MM-dd
        let simpleFormatter = DateFormatter()
        simpleFormatter.dateFormat = "yyyy-MM-dd"
        if let date = simpleFormatter.date(from: dateString) { return date }
        
        return nil
    }
    
    private func formatTime(_ rawRange: String) -> String {
        let parts = rawRange.components(separatedBy: " - ")
        if parts.count == 2 {
            return "\(formatSingleTime(parts[0])) - \(formatSingleTime(parts[1]))"
        }
        return rawRange
    }
    
    private func formatSingleTime(_ time: String) -> String {
        let components = time.split(separator: ":")
        guard let hour = Int(components[0]) else { return time }
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour):00 \(period)"
    }
    
    
    // MARK: - Debug Method (Corrected)

    func debugAnalytics() {
        Task {
            print("\n========== 📊 ANALYTICS DEBUG START ==========\n")

            do {
                let (appointments, slots, staff) = try await fetchAnalyticsData()

                // MARK: - Data Summary
                print("✅ Data Fetched Successfully")
                print("• Appointments: \(appointments.count)")
                print("• Time Slots: \(slots.count)")
                print("• Staff: \(staff.count)\n")

                // MARK: - Core Insights
                print("📈 CORE INSIGHTS")
                print("🗓️ Busiest Day:", calculateBusiestDay(from: appointments))
                print("⏰ Busiest Time Slot:", calculateBusiestTimeSlot(from: slots))
                print("👨‍⚕️ Most Occupied Staff:",
                      calculateMostOccupiedStaff(
                        appointments: appointments,
                        staffList: staff
                      )
                )
                // MARK: - Staff Suggestions for High-Demand Days
                print("\n👥 STAFF SUGGESTIONS FOR HIGH-DEMAND DAYS")

                let staffByDay = staffSuggestionsForHighDemandDays(
                    appointments: appointments,
                    staffList: staff
                )

                for (day, staffMembers) in staffByDay.sorted(by: { $0.key < $1.key }) {
                    print("\n📅 \(day):")
                    for member in staffMembers.prefix(3) {
                        print("• \(member.fullName)")
                    }
                }



                // MARK: - Predictions
                print("\n🔮 PREDICTIONS")
                print("Patient Load:", predictPatientLoad(appointments: appointments))

                print("\n📋 Staff Allocation (Demand-Based)")
                let staffInsights = predictStaffRequirementV2(
                    appointments: appointments,
                    slots: slots
                )

                for insight in staffInsights {
                    print("• \(insight)")
                }

                // MARK: - Personalized Suggestions
                if let patientId = appointments.first?.patientId {
                    print("\n💡 PERSONALIZED SLOT SUGGESTIONS")
                    print("Simulated Patient ID:", patientId)

                    let suggestions = suggestAppointmentSlots(
                        for: patientId,
                        history: appointments,
                        slots: slots,
                        staff: staff
                    )

                    for (index, suggestion) in suggestions.enumerated() {
                        print("\(index + 1). \(suggestion)")
                    }
                } else {
                    print("\n⚠️ No patient history available for slot suggestions.")
                }

                print("\n========== ✅ ANALYTICS DEBUG END ==========\n")

            } catch {
                print("\n❌ Analytics Error:", error)
            }
        }
    }

}
