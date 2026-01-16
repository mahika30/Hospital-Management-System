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
            
        if let chosenSlot = selectedSlot {
            return try await bookSlot(service: service, slotId: chosenSlot.id, slotTime: chosenSlot.time)
        }
        
        let slots = try await service.fetchAvailableSlots(staffId: doctor.id, date: date)
        
        if slots.isEmpty {
            throw IntentError.message("No available slots for \(doctor.name) on \(date.formatted(date: .abbreviated, time: .omitted)).")
        }
        

        let slotEntities = slots.map { TimeSlotEntity(from: $0, doctorName: doctor.name) }

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

// MARK: - Doctor Intents

@available(iOS 16.0, *)
struct DoctorAppointmentCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Doctor Appointment Count"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Date")
    var requestedDate: String?
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        
        let staffId = try await IntentRoleGuard.validate(role: .staff)
        
        let date: Date
        let dateLabel: String
        
        if let input = requestedDate?.lowercased() {
             if input.contains("tomorrow") {
                 date = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
                 dateLabel = "tomorrow"
             } else {
                 date = Date()
                 dateLabel = "today"
             }
        } else {
             date = Date()
             dateLabel = "today"
        }
        
        let count = try await AppointmentService().fetchDoctorAppointmentsCount(staffId: staffId, for: date)
        
        let msg = "You have \(count) appointments \(dateLabel)."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, *)
struct DoctorOpenAllSlotsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open All Slots"
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let staffId = try await IntentRoleGuard.validate(role: .staff)
        try await AppointmentService().toggleSlotAvailability(staffId: staffId, date: Date(), makeAvailable: true)
        let msg = "I have opened all your slots for today."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, *)
struct DoctorCloseAllSlotsIntent: AppIntent {
    static var title: LocalizedStringResource = "Close All Slots"
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let staffId = try await IntentRoleGuard.validate(role: .staff)
        try await AppointmentService().toggleSlotAvailability(staffId: staffId, date: Date(), makeAvailable: false)
        let msg = "I have closed all your slots for today."
        return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
    }
}

@available(iOS 16.0, *)
struct DoctorCloseSpecificSlotIntent: AppIntent {
    static var title: LocalizedStringResource = "Close Specific Slot"
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Slot")
    var targetSlot: TimeSlotEntity?
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        let staffId = try await IntentRoleGuard.validate(role: .staff)
        let date = Date()
        
        if let slot = targetSlot {
            try await AppointmentService().toggleSpecificSlot(slotId: slot.id, makeAvailable: false)
            let msg = "I have closed the slot at \(slot.time)."
            return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        } else {
            let service = await AppointmentService()
             let rawSlots = try await service.fetchAvailableSlotsForDoctor(staffId: staffId, date: date)
             
             if rawSlots.isEmpty {
                 let msg = "You don't have any open slots to close for today."
                 return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
             }
             
             let entities = rawSlots.map { TimeSlotEntity(from: $0, doctorName: "You") }
             
             let chosen = try await $targetSlot.requestDisambiguation(
                 among: entities,
                 dialog: "Which slot would you like to close?"
             )
             
             try await service.toggleSpecificSlot(slotId: chosen.id, makeAvailable: false)
             let msg = "I have closed the slot at \(chosen.time)."
             return .result(value: msg, dialog: IntentDialog(stringLiteral: msg))
        }
    }
}

@available(iOS 16.0, *)
struct AdminAnalyticsIntent: AppIntent {
    static var title: LocalizedStringResource = "Admin Dashboard Analytics"
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> & ProvidesDialog {
        
        let _ = try await IntentRoleGuard.validate(role: .admin)
        
        // Fetch Data
        let (allAppts, _, allStaff) = try await AnalyticsService.shared.fetchAnalyticsData()
        
        let service = await AnalyticsService.shared
        
        let today = Date()
        let calendar = Calendar.current
        let todayAppts = allAppts.filter { appt in
            let isoFormatter = ISO8601DateFormatter()
            isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            guard let date = ISO8601DateFormatter().date(from: appt.appointmentDate) ??
                            ISO8601DateFormatter().date(from: appt.appointmentDate.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression))
            else { return false }
            
            return calendar.isDate(date, inSameDayAs: today)
        }
        
        let totalAppointments = todayAppts.count
        let footfall = Set(todayAppts.map { $0.patientId }).count
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        let thisWeekAppts = allAppts.filter { appt in
            guard let date = ISO8601DateFormatter().date(from: appt.appointmentDate) ?? ISO8601DateFormatter().date(from: appt.appointmentDate.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)) else { return false }
            return date >= startOfWeek
        }
        let busiestDay = await service.calculateBusiestDay(from: thisWeekAppts)
        let busiestDoctorToday = await service.calculateMostOccupiedStaff(appointments: todayAppts, staffList: allStaff)
        let spoken = """
        Today's footfall is \(footfall) patients.
        There are \(totalAppointments) appointments.
        \(busiestDay) is the busiest day this week.
        \(busiestDoctorToday) is the busiest doctor today.
        """
        
        return .result(value: spoken, dialog: IntentDialog(stringLiteral: spoken))
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
