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

    private let supabase = SupabaseManager.shared.client

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
}
