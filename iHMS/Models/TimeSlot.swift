//
//  TimeSlot.swift
//  iHMS
//
//  Created on 08/01/2026.
//

import Foundation

struct TimeSlot: Identifiable, Codable, Hashable {
    let id: UUID
    let staffId: UUID
    let slotDate: String
    var startTime: String
    var endTime: String
    var isAvailable: Bool
    var currentBookings: Int
    var maxCapacity: Int
    var isRunningLate: Bool
    var delayMinutes: Int
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case staffId = "staff_id"
        case slotDate = "slot_date"
        case startTime = "start_time"
        case endTime = "end_time"
        case isAvailable = "is_available"
        case currentBookings = "current_bookings"
        case maxCapacity = "max_capacity"
        case isRunningLate = "is_running_late"
        case delayMinutes = "delay_minutes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // Helper: convert slotDate String → Date
    private var slotDateAsDate: Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: slotDate)
    }

    // Day name: Wednesday
    var dayName: String {
        guard let date = slotDateAsDate else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    // Short day name: Wed
    var shortDayName: String {
        guard let date = slotDateAsDate else { return "-" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    // Formatted date: Jan 9, 2026
    var formattedDate: String {
        guard let date = slotDateAsDate else { return slotDate }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    var timeRange: String {
        "\(formatTime(startTime)) - \(formatTime(endTime))"
    }
    
    private func formatTime(_ time: String) -> String {
        // Convert "09:00:00" to "9:00 AM"
        let components = time.split(separator: ":")
        guard let hour = Int(components[0]) else { return time }
        
        let period = hour >= 12 ? "PM" : "AM"
        let displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour)
        return "\(displayHour):00 \(period)"
    }
    
    var isFull: Bool {
        currentBookings >= maxCapacity
    }
    
    var availableSlots: Int {
        max(0, maxCapacity - currentBookings)
    }
    
    var fillPercentage: Double {
        guard maxCapacity > 0 else { return 0 }
        return Double(currentBookings) / Double(maxCapacity)
    }
    
    var status: SlotStatus {
        if !isAvailable {
            return .disabled
        } else if isFull {
            return .full
        } else if fillPercentage >= 0.7 {
            return .filling
        } else {
            return .available
        }
    }
    
    // Helper to get hour from time string for grouping
    var hour: Int {
        let components = startTime.split(separator: ":")
        return Int(components[0]) ?? 0
    }
}

enum SlotStatus: String {
    case available = "Available"
    case filling = "Filling Up"
    case full = "Full"
    case disabled = "Disabled"
    case runningLate = "Running Late"
    
    var color: String {
        switch self {
        case .available: return "green"
        case .filling: return "orange"
        case .full: return "red"
        case .disabled: return "gray"
        case .runningLate: return "yellow"
        }
    }
}
