import AppIntents
import Foundation
import Supabase
import Auth

@available(iOS 16.0, *)
struct StaffEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Doctor"
    
    var id: UUID
    var name: String
    var department: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(stringLiteral: name)
    }
    
    static var defaultQuery = StaffQuery()
    
    init(id: UUID, name: String, department: String) {
        self.id = id
        self.name = name
        self.department = department
    }
    
    init(from staff: Staff) {
        self.id = staff.id
        self.name = staff.fullName
        self.department = staff.specialization ?? "General"
    }
}

@available(iOS 16.0, *)
struct StaffQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [StaffEntity] {
        let service = await MainActor.run { StaffService() }
        let allStaff = try await service.fetchStaff()
        return allStaff
            .filter { identifiers.contains($0.id) }
            .map { StaffEntity(from: $0) }
    }
    
    func suggestedEntities() async throws -> [StaffEntity] {
        let service = await MainActor.run { StaffService() }
        let allStaff = try await service.fetchStaff()
        return allStaff.map { StaffEntity(from: $0) }
    }
}

@available(iOS 16.0, *)
struct AppointmentEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Appointment"
    
    var id: UUID
    var doctorName: String
    var date: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(doctorName)", subtitle: "\(date)")
    }
    
    static var defaultQuery = AppointmentQuery()
    
    init(id: UUID, doctorName: String, date: String) {
        self.id = id
        self.doctorName = doctorName
        self.date = date
    }
    
    init(from appointment: Appointment) {
        self.id = appointment.id
        self.doctorName = appointment.staff?.fullName ?? "Doctor"
        self.date = appointment.formattedDate + " " + appointment.formattedTime
    }
}

@available(iOS 16.0, *)
struct AppointmentQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [AppointmentEntity] {
        guard let patientId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            return []
        }
        
        let service = await MainActor.run { AppointmentService() }
        let appointments = try await service.fetchAppointments(for: patientId)
        return appointments
            .filter { identifiers.contains($0.id) }
            .map { AppointmentEntity(from: $0) }
    }
    
    func suggestedEntities() async throws -> [AppointmentEntity] {
        guard let patientId = try? await SupabaseManager.shared.client.auth.session.user.id else {
            return []
        }
        
        let service = await MainActor.run { AppointmentService() }
        let appointments = try await service.fetchAppointments(for: patientId)
        return appointments
            .filter { $0.status == "scheduled" || $0.status == "confirmed" }
            .map { AppointmentEntity(from: $0) }
    }
}

@available(iOS 16.0, *)
struct TimeSlotEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Time Slot"
    
    var id: UUID
    var time: String
    var doctorName: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(time)", subtitle: "\(doctorName)")
    }
    
    static var defaultQuery = TimeSlotQuery()
    
    init(id: UUID, time: String, doctorName: String) {
        self.id = id
        self.time = time
        self.doctorName = doctorName
    }
    
    init(from slot: TimeSlot, doctorName: String) {
        self.id = slot.id
        self.time = TimeSlotEntity.formatTime(slot.startTime)
        self.doctorName = doctorName
    }
    
    static func formatTime(_ time: String) -> String {
        let parts = time.split(separator: ":")
        guard let hourStr = parts.first, let hour = Int(hourStr) else { return time }
        let minutes = parts.count > 1 ? String(parts[1]) : "00"
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour):\(minutes) \(period)"
    }
}

@available(iOS 16.0, *)
struct TimeSlotQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [TimeSlotEntity] {
        
        let client = await SupabaseManager.shared.client
        let slots: [TimeSlot] = try await client
            .from("time_slots")
            .select()
            .in("id", values: identifiers.map { $0.uuidString })
            .execute()
            .value
            
        return slots.map { TimeSlotEntity(from: $0, doctorName: "Doctor") }
    }
    
    func suggestedEntities() async throws -> [TimeSlotEntity] {
        return []
    }
}

enum SlotManageAction: String, AppEnum {
    case openAll = "open all"
    case closeAll = "close all"
    case closeSpecific = "close specific"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Slot Action"
    
    static var caseDisplayRepresentations: [SlotManageAction : DisplayRepresentation] = [
        .openAll: "Open All Slots",
        .closeAll: "Close All Slots",
        .closeSpecific: "Close A Slot"
    ]
}
