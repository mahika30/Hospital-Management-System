//
//  AnalyticsTimeSlotDTO.swift
//  iHMS
//
//  Created by Hargun Singh on 13/01/26.
//
import Foundation
struct AnalyticsTimeSlotDTO: Codable {
    let id: UUID
    let staffId: UUID
    let slotDate: String
    let startTime: String
    let endTime: String
    let currentBookings: Int
    let maxCapacity: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case staffId = "staff_id"
        case slotDate = "slot_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case currentBookings = "current_bookings"
        case maxCapacity = "max_capacity"
    }
}
