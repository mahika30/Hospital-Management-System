//
//  AnalyticsAppointmentDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 13/01/26.
//

import Foundation

struct AnalyticsAppointmentDTO: Codable {
    let id: UUID
    let appointmentDate: String
    let appointmentTime: String?
    let patientId: UUID
    let staffId: UUID
    let timeSlotId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentDate = "appointment_date"
        case appointmentTime = "appointment_time"
        case patientId = "patient_id"
        case staffId = "staff_id"
        case timeSlotId = "time_slot_id"
    }
}
