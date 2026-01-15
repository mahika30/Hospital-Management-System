//
//  Feedback.swift
//  iHMS
//
//  Created by Deepanshu Garg on 15/01/26.
//


import Foundation

/// Enum to represent who submitted the feedback
enum FeedbackSubmitter: String, Codable {
    case patient = "patient"
    case doctor = "doctor"
    
    var displayName: String {
        switch self {
        case .patient: return "Patient"
        case .doctor: return "Doctor"
        }
    }
}


/// Model representing feedback for a completed appointment
struct Feedback: Identifiable, Codable {
    
    let id: UUID
    let appointmentId: UUID
    let patientId: UUID
    let doctorId: UUID
    let submittedBy: String
    let rating: Int?
    let comments: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case appointmentId = "appointment_id"
        case patientId = "patient_id"
        case doctorId = "doctor_id"
        case submittedBy = "submitted_by"
        case rating
        case comments
        case createdAt = "created_at"
    }
    
    /// Computed property to get the submitter type
    var submitter: FeedbackSubmitter {
        FeedbackSubmitter(rawValue: submittedBy) ?? .patient
    }
    
    /// Formatted date string for display
    var formattedDate: String {
        guard let createdAtString = createdAt else { return "Unknown date" }
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = isoFormatter.date(from: createdAtString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        
        return createdAtString
    }
    
    /// Star rating display (e.g., "⭐️⭐️⭐️⭐️⭐️")
    var starRating: String {
        guard let rating = rating else { return "No rating" }
        return String(repeating: "⭐️", count: rating)
    }
}

