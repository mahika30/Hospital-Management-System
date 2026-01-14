import Foundation
import SwiftUI
import Combine
import Supabase
import PostgREST

@MainActor
final class BookAppointmentViewModel: ObservableObject {
    

    @Published var selectedDate: Date = Date()
    @Published var timeSlots: [TimeSlot] = []
    @Published var selectedSlot: TimeSlot?
    @Published var isLoading = false
    @Published var bookingSuccess = false
    @Published var errorMessage: String?
    @Published var suggestedSlots: [SuggestedSlot] = []
    @Published var isLoadingSuggestions = false

    private let supabase = SupabaseManager.shared.client
    
    struct SuggestedSlot: Identifiable {
        let id: UUID
        let staffId: UUID
        let staffName: String
        let date: String
        let timeRange: String
        let reason: String
        let score: Double
    }

    // MARK: - Load Slots
    func loadSlots(staffId: UUID, date: Date) async {
        isLoading = true

        let dateString = formatDateForQuery(date)
        print("🔍 Loading slots for date: \(dateString)")

        do {
            let slots: [TimeSlot] = try await supabase
                .from("time_slots")
                .select()
                .eq("staff_id", value: staffId.uuidString)
                .eq("slot_date", value: dateString)
                .eq("is_available", value: true)
                .order("start_time", ascending: true)
                .execute()
                .value

            timeSlots = slots.filter { !$0.isFull }
            selectedSlot = nil
            print("✅ Loaded \(timeSlots.count) available slots")
        } catch {
            errorMessage = "Failed to load time slots"
            print("❌ Error loading slots: \(error)")
        }

        isLoading = false
    }
    
    private func formatDateForQuery(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    private func isoDate(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.string(from: date)
    }

    // MARK: - Book Appointment
    func bookAppointment(doctorId: UUID) async {
        guard let slot = selectedSlot else { return }

        isLoading = true
        errorMessage = nil

        do {
            // Get authenticated patient ID
            guard let userId = try? await supabase.auth.session.user.id else {
                errorMessage = "Not authenticated"
                isLoading = false
                return
            }

            // Insert appointment
            try await supabase
                .from("appointments")
                .insert([
                    "patient_id": userId.uuidString,
                    "staff_id": doctorId.uuidString,
                    "time_slot_id": slot.id.uuidString,
                    "appointment_date": formatDateForQuery(selectedDate),
                    "status": "scheduled"
                ])
                .execute()

            print("✅ Appointment created successfully")
            bookingSuccess = true
            selectedSlot = nil
            
            // Reload slots to refresh availability
            await loadSlots(staffId: doctorId, date: selectedDate)
            
        } catch {
            errorMessage = "Failed to book appointment: \(error.localizedDescription)"
            print("❌ Booking error: \(error)")
        }

        isLoading = false
    }
    
    // MARK: - AI Slot Suggestions
    func loadAISuggestions(forDoctor staffId: UUID) async {
        isLoadingSuggestions = true
        suggestedSlots = []
        
        do {
            // Get authenticated patient ID
            guard let patientId = try? await supabase.auth.session.user.id else {
                print("❌ Not authenticated")
                isLoadingSuggestions = false
                return
            }
            
            print("🤖 Loading AI suggestions for patient: \(patientId), doctor: \(staffId)")
            
            // Fetch analytics data
            let (appointments, slots, staff) = try await AnalyticsService.shared.fetchAnalyticsData()
            
            // Filter appointments for THIS doctor only (all patients)
            let doctorAppointments = appointments.filter { $0.staffId == staffId }
            
            // Filter slots for selected doctor only
            let doctorSlots = slots.filter { $0.staffId == staffId }
            
            print("📊 Analytics data: \(doctorAppointments.count) appointments for this doctor, \(doctorSlots.count) available slots")
            
            // Get AI suggestions using THIS doctor's appointment history
            let suggestions = AnalyticsService.shared.suggestAppointmentSlots(
                for: patientId,
                history: doctorAppointments,
                slots: doctorSlots,
                staff: staff,
                limit: 5
            )
            
            print("💡 Raw AI suggestions: \(suggestions)")
            
            // If no personalized suggestions (new patient), show general best slots
            if suggestions.count == 1 && suggestions[0].contains("No slots available") {
                print("⚠️ No slots available")
                isLoadingSuggestions = false
                return
            }
            
            // Parse suggestions into structured data
            var parsedSlots: [SuggestedSlot] = []
            
            for (index, suggestion) in suggestions.enumerated() {
                // Parse format: "2026-01-15 @ 10:00 AM - 11:00 AM with Dr. John Doe (⭐ Your Doctor)"
                let components = suggestion.components(separatedBy: " @ ")
                guard components.count == 2 else {
                    print("⚠️ Failed to parse suggestion: \(suggestion)")
                    continue
                }
                
                let date = components[0].trimmingCharacters(in: .whitespaces)
                let rest = components[1].components(separatedBy: " with ")
                guard rest.count == 2 else {
                    print("⚠️ Failed to parse doctor info: \(suggestion)")
                    continue
                }
                
                let timeRange = rest[0].trimmingCharacters(in: .whitespaces)
                let doctorInfo = rest[1].trimmingCharacters(in: .whitespaces)
                
                // Extract doctor name and reason
                var doctorName = doctorInfo
                var reason = "Recommended for you"
                
                if doctorInfo.contains("(⭐ Your Doctor)") {
                    doctorName = doctorInfo.replacingOccurrences(of: " (⭐ Your Doctor)", with: "")
                    reason = "Your preferred doctor"
                }
                
                print("🔍 Looking for slot: date=\(date), time=\(timeRange), doctor=\(doctorName)")
                
                // Find matching staff first
                guard let matchingStaff = staff.first(where: { $0.fullName == doctorName }) else {
                    print("⚠️ Staff not found: \(doctorName)")
                    continue
                }
                
                // Convert time range to match database format
                // "10:00 AM - 11:00 AM" needs to match slots with startTime="10:00:00", endTime="11:00:00"
                let timeParts = timeRange.components(separatedBy: " - ")
                guard timeParts.count == 2 else {
                    print("⚠️ Invalid time range format: \(timeRange)")
                    continue
                }
                
                // Find matching slot with flexible time matching
                if let matchingSlot = slots.first(where: { slot in
                    let dateMatches = slot.slotDate == date
                    // Format slot times for comparison
                    let slotTimeRange = formatTimeFromDB(slot.startTime, slot.endTime)
                    let timeMatches = slotTimeRange == timeRange
                    
                    if dateMatches && timeMatches && slot.staffId == matchingStaff.id {
                        return true
                    }
                    return false
                }) {
                    
                    parsedSlots.append(SuggestedSlot(
                        id: matchingSlot.id,
                        staffId: matchingStaff.id,
                        staffName: doctorName,
                        date: date,
                        timeRange: timeRange,
                        reason: reason,
                        score: Double(5 - index)
                    ))
                    
                    print("✅ Matched slot: \(date) @ \(timeRange)")
                } else {
                    print("⚠️ No matching slot found for: \(date) @ \(timeRange) with \(doctorName)")
                }
            }
            
            suggestedSlots = parsedSlots
            print("✅ Loaded \(suggestedSlots.count) AI suggestions")
            
        } catch {
            print("❌ Error loading AI suggestions: \(error)")
        }
        
        isLoadingSuggestions = false
    }
    
    private func formatTimeFromDB(_ startTime: String, _ endTime: String) -> String {
        // Convert "10:00:00" to "10:00 AM"
        func convertTime(_ time: String) -> String {
            let components = time.split(separator: ":")
            guard let hour = Int(components[0]) else { return time }
            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
            return "\(displayHour):00 \(period)"
        }
        
        return "\(convertTime(startTime)) - \(convertTime(endTime))"
    }
    
    private func formatTimeRange(_ range: String) -> String {
        // Already formatted by analytics service
        return range
    }

    // MARK: - Book Appointment (Return ID for Payments)
    func bookAppointmentAndReturnId(doctorId: UUID) async throws -> UUID {
        guard let slot = selectedSlot else {
            throw NSError(domain: "Slot", code: 0)
        }

        let userId = try await supabase.auth.session.user.id

        struct AppointmentResponse: Decodable {
            let id: UUID
        }

        let response: AppointmentResponse = try await supabase
            .from("appointments")
            .insert([
                "patient_id": userId.uuidString,
                "staff_id": doctorId.uuidString,
                "time_slot_id": slot.id.uuidString,
                "appointment_date": formatDateForQuery(selectedDate),
                "status": "scheduled"
            ])
            .select("id")
            .single()
            .execute()
            .value

        bookingSuccess = true
        return response.id
    }


}

struct AppointmentIdResponse: Decodable {
    let id: UUID
}
