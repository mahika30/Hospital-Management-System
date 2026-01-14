import AppIntents
import Foundation
import SwiftUI
import Supabase
import Auth

@available(iOS 16.0, *)
struct BookAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Book Appointment"
    static var description: IntentDescription = IntentDescription("Book a doctor appointment")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Doctor")
    var doctor: StaffEntity
    
    @Parameter(title: "Date")
    var date: Date
    
    @Parameter(title: "Time Slot")
    var selectedSlot: TimeSlotEntity?
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        // Init service
        let service = await MainActor.run { AppointmentService() }
        
        // 1. If we already have a selected slot from disambiguation param, book it.
        if let chosenSlot = selectedSlot {
            return try await bookSlot(service: service, slotId: chosenSlot.id, slotTime: chosenSlot.time)
        }
        
        // 2. Otherwise, fetch valid slots for the requested date
        let slots = try await service.fetchAvailableSlots(staffId: doctor.id, date: date)
        
        if slots.isEmpty {
            throw IntentError.message("No available slots for \(doctor.name) on \(date.formatted(date: .abbreviated, time: .omitted)).")
        }
        
        // 3. Convert to Entities
        let slotEntities = slots.map { TimeSlotEntity(from: $0, doctorName: doctor.name) }
        
        // 4. Ask user to pick one
        // Siri will present a list or read them out
        let chosenToken = try await $selectedSlot.requestDisambiguation(
            among: slotEntities,
            dialog: "I found \(slots.count) available slots. Which one would you like?"
        )
        
        // 5. Book the chosen one
        return try await bookSlot(service: service, slotId: chosenToken.id, slotTime: chosenToken.time)
    }
    
    private func bookSlot(service: AppointmentService, slotId: UUID, slotTime: String) async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        guard let patientId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            throw IntentError.message("You must be logged in to book appointments.")
        }

        try await service.createAppointment(
            patientId: patientId,
            staffId: doctor.id,
            timeSlotId: slotId,
            appointmentDate: date
        )
        
        let dateString = date.formatted(date: .abbreviated, time: .omitted)
        let msg = "Booked with \(doctor.name) on \(dateString) at \(slotTime)."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, *)
struct RescheduleAppointmentIntent: AppIntent {
    static var title: LocalizedStringResource = "Reschedule Appointment"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Appointment")
    var appointment: AppointmentEntity
    
    @Parameter(title: "New Date")
    var newDate: Date
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let service = await MainActor.run { AppointmentService() }
        
        guard let patientId = try? await SupabaseManager.shared.client.auth.session.user.id else {
             throw IntentError.message("Authentication required.")
        }
        
        let appointments = try await service.fetchAppointments(for: patientId)
        guard let fullAppointment = appointments.first(where: { $0.id == appointment.id }) else {
            throw IntentError.message("Appointment not found.")
        }
        
        let staffId = fullAppointment.staffId 
        
        // Find new slot
        let slots = try await service.fetchAvailableSlots(staffId: staffId, date: newDate)
        guard let firstSlot = slots.first else {
            throw IntentError.message("No slots available on that date.")
        }
        
        try await service.rescheduleAppointment(
            appointmentId: appointment.id,
            newSlotId: firstSlot.id,
            newDate: newDate
        )
        
        let dateStr = newDate.formatted(date: .abbreviated, time: .omitted)
        let msg = "Rescheduled to \(dateStr)"
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, *)
struct CheckAppointmentStatusIntent: AppIntent {
    static var title: LocalizedStringResource = "Check Appointment Status"
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        
        let pId = await getPatientId()
        
        guard let validId = pId else {
             return .result(value: "Please log in first.", dialog: "Please log in to the iHMS app first.")
        }
        
        do {
            let result = try await fetchStatus(patientId: validId)
            return .result(value: result.message, dialog: IntentDialog(stringLiteral: result.spoken))
        } catch {
             return .result(value: "Error.", dialog: "I had trouble getting your status.")
        }
    }
    
    @MainActor
    private func getPatientId() async -> UUID? {
        // Accessing shared (MainActor) and session (Async)
        try? await SupabaseManager.shared.client.auth.session.user.id
    }
    
    struct StatusResult {
        let message: String
        let spoken: String
    }
    
    @MainActor
    private func fetchStatus(patientId: UUID) async throws -> StatusResult {
        let service = AppointmentService()
        let appointments = try await service.fetchAppointments(for: patientId)
        
        let now = Date()
        let upcoming = appointments.filter { appointment in
            let statusOk = (appointment.status == "scheduled" || appointment.status == "confirmed")
            guard let date = appointment.parsedDate else { return false }
            return statusOk && date >= now
        }
            
        if let nearest = upcoming.first {
            let status = nearest.status.capitalized
            let details = "Your next appointment is with \(nearest.doctorName) on \(nearest.formattedDate). The status is \(status)."
            return StatusResult(message: details, spoken: details)
        } else {
            let msg = "You have no upcoming appointments."
            return StatusResult(message: msg, spoken: msg)
        }
    }
}

import EventKit

@available(iOS 16.0, *)
struct AppointmentReminderIntent: AppIntent {
    static var title: LocalizedStringResource = "Remind Me About Appointment"
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Appointment")
    var appointment: AppointmentEntity?
    
    struct ReminderResult {
        let message: String
        let spoken: String
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        
        if let appt = appointment {
             // In this case, we have the simplified Entity.
             // We need the full appointment to get the exact date for the system reminder.
             // So we should fetch it or try to parse what we have.
             // But simpler strategy: Use the same fallback logic to fetch fresh data using ID if needed, 
             // or just trust the simplified entity if we can.
             // Actually, AppointmentEntity stores 'id'. We can fetch the full object to ensure accuracy.
             
             let pId = await getPatientId()
             guard let validId = pId else {
                 return .result(value: "Please log in.", dialog: "Please log in first.")
             }
             
             do {
                 let result = try await createSystemReminderFor(appointmentId: appt.id, patientId: validId)
                 return .result(value: result.message, dialog: IntentDialog(stringLiteral: result.spoken))
             } catch {
                 return .result(value: "Error: \(error.localizedDescription)", dialog: "I couldn't create the reminder. Please check permissions.")
             }
        }
        
        // Fallback: Find nearest
        let pId = await getPatientId()
        
        guard let validId = pId else {
             return .result(value: "Please log in.", dialog: "Please log in first.")
        }
        
        do {
            let result = try await findNearestAndRemind(patientId: validId)
            return .result(value: result.message, dialog: IntentDialog(stringLiteral: result.spoken))
        } catch {
             return .result(value: "Error.", dialog: "I couldn't set the reminder.")
        }
    }
    
    @MainActor
    private func getPatientId() async -> UUID? {
        try? await SupabaseManager.shared.client.auth.session.user.id
    }
    
    @MainActor
    private func findNearestAndRemind(patientId: UUID) async throws -> ReminderResult {
        let service = AppointmentService()
        let appointments = try await service.fetchAppointments(for: patientId)
        
        let now = Date()
        let nearest = appointments.first(where: { appointment in
            let statusOk = (appointment.status == "scheduled" || appointment.status == "confirmed")
            guard let date = appointment.parsedDate else { return false }
            return statusOk && date >= now
        })
        
        if let next = nearest {
             // Create System Reminder
             try await createSystemReminder(for: next)
             
             let name = next.doctorName
             let msg = "Okay, I've added a reminder to your default list for your appointment with \(name)."
             return ReminderResult(message: msg, spoken: msg)
        } else {
            let msg = "You don't have any upcoming appointments to remind you about."
            return ReminderResult(message: msg, spoken: msg)
        }
    }
    
    @MainActor
    private func createSystemReminderFor(appointmentId: UUID, patientId: UUID) async throws -> ReminderResult {
        let service = AppointmentService()
        let appointments = try await service.fetchAppointments(for: patientId)
        
        guard let match = appointments.first(where: { $0.id == appointmentId }) else {
            throw IntentError.message("Appointment not found.")
        }
        
        try await createSystemReminder(for: match)
        let name = match.doctorName
        let msg = "Okay, I've added a reminder to your list for your appointment with \(name)."
        return ReminderResult(message: msg, spoken: msg)
    }

    @MainActor
    private func createSystemReminder(for appointment: Appointment) async throws {
        let store = EKEventStore()
        
        // Request Access (this might hang if in background and permission not deterimined, but correct API usage)
        let granted: Bool
        if #available(iOS 17.0, *) {
             granted = try await store.requestFullAccessToReminders()
        } else {
             granted = try await store.requestAccess(to: .reminder)
        }
        
        guard granted else {
            throw IntentError.message("Please open the app and grant access to Reminders.")
        }
        
        let reminder = EKReminder(eventStore: store)
        reminder.title = "Appointment with \(appointment.doctorName)"
        let notes = "Status: \(appointment.status.capitalized)\nTime: \(appointment.formattedTime)"
        reminder.notes = notes
        
        if let date = appointment.parsedDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
            // Add an alarm 1 hour before
            reminder.addAlarm(EKAlarm(absoluteDate: date.addingTimeInterval(-3600)))
        }
        
        reminder.calendar = store.defaultCalendarForNewReminders()
        try store.save(reminder, commit: true)
    }
}

enum IntentError: Swift.Error, CustomLocalizedStringResourceConvertible {
    case message(String)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .message(let string):
            return LocalizedStringResource(stringLiteral: string)
        }
    }
}
