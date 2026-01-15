//
//  FeedbackService.swift
//  iHMS
//
//  Created by Deepanshu Garg on 15/01/26.
//


//
//  FeedbackService.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import Supabase

final class FeedbackService {
    
    /// Submit feedback for a completed appointment
    /// - Parameters:
    ///   - appointmentId: The ID of the appointment
    ///   - patientId: The ID of the patient
    ///   - doctorId: The ID of the doctor/staff
    ///   - submittedBy: Who is submitting the feedback ("patient" or "doctor")
    ///   - rating: Rating value (1-5), optional for doctors
    ///   - comments: Optional comments
    func submitFeedback(
        appointmentId: UUID,
        patientId: UUID,
        doctorId: UUID,
        submittedBy: FeedbackSubmitter,
        rating: Int?,
        comments: String?
    ) async throws {
        
        // Create the feedback payload
        struct FeedbackInsert: Encodable {
            let appointment_id: UUID
            let patient_id: UUID
            let doctor_id: UUID
            let submitted_by: String
            let rating: Int?
            let comments: String?
        }
        
        let payload = FeedbackInsert(
            appointment_id: appointmentId,
            patient_id: patientId,
            doctor_id: doctorId,
            submitted_by: submittedBy.rawValue,
            rating: rating,
            comments: comments
        )
        
        // Insert into Supabase
        try await SupabaseManager.shared.client
            .from("feedbacks")
            .insert(payload)
            .execute()
    }
    
    /// Check if feedback already exists for a specific appointment and submitter
    /// - Parameters:
    ///   - appointmentId: The appointment ID
    ///   - submittedBy: Who submitted the feedback
    /// - Returns: True if feedback exists, false otherwise
    func checkFeedbackExists(
        appointmentId: UUID,
        submittedBy: FeedbackSubmitter
    ) async throws -> Bool {
        
        let feedbacks: [Feedback] = try await SupabaseManager.shared.client
            .from("feedbacks")
            .select("*")
            .eq("appointment_id", value: appointmentId.uuidString)
            .eq("submitted_by", value: submittedBy.rawValue)
            .limit(1)
            .execute()
            .value
        
        return !feedbacks.isEmpty
    }
    
    /// Fetch all feedback for a specific appointment
    /// - Parameter appointmentId: The appointment ID
    /// - Returns: Array of feedback records
    func fetchFeedbackForAppointment(appointmentId: UUID) async throws -> [Feedback] {
        
        let feedbacks: [Feedback] = try await SupabaseManager.shared.client
            .from("feedbacks")
            .select("*")
            .eq("appointment_id", value: appointmentId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return feedbacks
    }
    
    /// Fetch feedback submitted by a specific user for an appointment
    /// - Parameters:
    ///   - appointmentId: The appointment ID
    ///   - submittedBy: The submitter type (patient or doctor)
    /// - Returns: The feedback if it exists, nil otherwise
    func fetchFeedback(
        appointmentId: UUID,
        submittedBy: FeedbackSubmitter
    ) async throws -> Feedback? {
        
        let feedbacks: [Feedback] = try await SupabaseManager.shared.client
            .from("feedbacks")
            .select("*")
            .eq("appointment_id", value: appointmentId.uuidString)
            .eq("submitted_by", value: submittedBy.rawValue)
            .limit(1)
            .execute()
            .value
        
        return feedbacks.first
    }
    
    /// Fetch all feedback for a specific doctor
    /// - Parameter doctorId: The doctor's ID
    /// - Returns: Array of feedback records
    func fetchDoctorFeedback(doctorId: UUID) async throws -> [Feedback] {
        
        let feedbacks: [Feedback] = try await SupabaseManager.shared.client
            .from("feedbacks")
            .select("*")
            .eq("doctor_id", value: doctorId.uuidString)
            .eq("submitted_by", value: "patient")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return feedbacks
    }
    
    /// Calculate average rating for a doctor
    /// - Parameter doctorId: The doctor's ID
    /// - Returns: Average rating (0.0 if no ratings)
    func calculateAverageRating(doctorId: UUID) async throws -> Double {
        
        let feedbacks = try await fetchDoctorFeedback(doctorId: doctorId)
        
        let ratings = feedbacks.compactMap { $0.rating }
        guard !ratings.isEmpty else { return 0.0 }
        
        let sum = ratings.reduce(0, +)
        return Double(sum) / Double(ratings.count)
    }
}

