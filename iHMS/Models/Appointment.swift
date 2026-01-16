import Foundation
import SwiftUI

enum AppointmentStatus: String, Codable, CaseIterable {
    case scheduled = "scheduled"
    case confirmed = "confirmed"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
    case noShow = "noShow"
    case rescheduled = "rescheduled"

    var displayName: String {
        switch self {
        case .scheduled: return "Scheduled"
        case .confirmed: return "Confirmed"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        case .noShow: return "No Show"
        case .rescheduled: return "Rescheduled"
        }
    }

    var color: Color {
        switch self {
        case .scheduled: return .blue
        case .confirmed: return .green
        case .inProgress: return .orange
        case .completed: return .gray
        case .cancelled: return .red
        case .noShow: return .orange
        case .rescheduled: return .purple
        }
    }
}


struct Appointment: Identifiable, Codable, Hashable {

    let id: UUID
    let patientId: UUID
    let staffId: UUID
    let timeSlotId: UUID?
    let appointmentDate: String

    let appointmentTime: String?
    let status: String

    let reasonForVisit: String?
    let notes: String?

    let createdAt: String?
    let updatedAt: String?
    var patient: Patient?
    var staff: Staff?
    var timeSlot: TimeSlot?

    enum CodingKeys: String, CodingKey {
        case id
        case patientId = "patient_id"
        case staffId = "staff_id"
        case timeSlotId = "time_slot_id"
        case appointmentDate = "appointment_date"
        case appointmentTime = "appointment_time"
        case status
        case reasonForVisit = "reason"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case patient = "patients"
        case staff
        case timeSlot = "time_slots"
    }

    var appointmentStatus: AppointmentStatus {
        AppointmentStatus(rawValue: status) ?? .scheduled
    }
    var parsedDate: Date? {
        // Try ISO8601 with various formats
        let isoFormatter = ISO8601DateFormatter()
        
        // Try with fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: appointmentDate) {
            return date
        }
        
        // Try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: appointmentDate) {
            return date
        }

        // Fallback to simple date format
        let fallback = DateFormatter()
        fallback.dateFormat = "yyyy-MM-dd"
        if let date = fallback.date(from: appointmentDate) {
            return date
        }
        
        // Last resort: try full ISO with timezone
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return fallback.date(from: appointmentDate)
    }

    // MARK: - FORMATTED DATE
    var formattedDate: String {
        guard let date = parsedDate else { return appointmentDate }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    // MARK: - FORMATTED TIME (slot → appointment_time → fallback)
    var formattedTime: String {
        let timeSource = appointmentTime ?? timeSlot?.startTime
        guard let time = timeSource else { return "Time not set" }

        let components = time.split(separator: ":")
        guard let hour = Int(components[0]) else { return time }

        let minutes = components.count > 1 ? components[1] : "00"
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)

        return "\(displayHour):\(minutes) \(period)"
    }

    // MARK: - DISPLAY STRING
    var displayDateTime: String {
        "\(formattedDate) • \(formattedTime)"
    }

    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Appointment, rhs: Appointment) -> Bool {
        lhs.id == rhs.id
    }
    
    var formattedSlot: String {
        guard let slot = timeSlot else { return "Time not set" }

        func format(_ time: String) -> String {
            let parts = time.split(separator: ":")
            guard let hour = Int(parts[0]) else { return time }

            let period = hour >= 12 ? "PM" : "AM"
            let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
            return "\(displayHour):\(parts[1]) \(period)"
        }

        return "\(format(slot.startTime)) – \(format(slot.endTime))"
    }
    
    var doctorName: String {
        staff?.fullName ?? "Doctor"
    }


}
