//
//  PatientFeedbackViewModel.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class PatientFeedbackViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var rating: Int = 0
    @Published var comments: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    
    // MARK: - Private Properties
    private let appointment: Appointment
    private let patientId: UUID
    private let feedbackService = FeedbackService()
    
    // MARK: - Initialization
    init(appointment: Appointment, patientId: UUID) {
        self.appointment = appointment
        self.patientId = patientId
    }
    
    // MARK: - Validation
    
    /// Validate that the rating is between 1 and 5
    var isRatingValid: Bool {
        rating >= 1 && rating <= 5
    }
    
    /// Check if the form can be submitted
    var canSubmit: Bool {
        isRatingValid && !isLoading
    }
    
    /// Validate appointment status
    private func validateAppointment() throws {
        guard appointment.status.lowercased() != "cancelled" else {
            throw FeedbackError.appointmentNotCompleted
        }
    }
    
    // MARK: - Feedback Submission
    
    /// Submit patient feedback for the appointment
    func submitFeedback() async {
        guard canSubmit else {
            errorMessage = "Please provide a rating between 1 and 5 stars"
            showErrorAlert = true
            return
        }
        
        isLoading = true
        errorMessage = nil
        showSuccessAlert = false
        showErrorAlert = false
        
        do {
            // Validate appointment status
            try validateAppointment()
            
            // Submit feedback (database unique constraint will prevent duplicates)
            try await feedbackService.submitFeedback(
                appointmentId: appointment.id,
                patientId: patientId,
                doctorId: appointment.staffId,
                submittedBy: .patient,
                rating: rating,
                comments: comments.isEmpty ? nil : comments
            )
            
            // Show success
            showSuccessAlert = true
            
        } catch FeedbackError.duplicateFeedback {
            errorMessage = "You have already submitted feedback for this appointment"
            showErrorAlert = true
        } catch FeedbackError.appointmentNotCompleted {
            errorMessage = "Feedback cannot be submitted for cancelled appointments"
            showErrorAlert = true
        } catch {
            // Check if it's a duplicate constraint error from database
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("duplicate") || errorString.contains("unique") || errorString.contains("idx_feedbacks_unique_submission") {
                errorMessage = "You have already submitted feedback for this appointment"
            } else {
                errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
            }
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    /// Check if feedback already exists for this appointment
    func checkExistingFeedback() async -> Bool {
        do {
            return try await feedbackService.checkFeedbackExists(
                appointmentId: appointment.id,
                submittedBy: .patient
            )
        } catch {
            print("Error checking existing feedback: \(error)")
            return false
        }
    }
}

// MARK: - Feedback Errors

enum FeedbackError: LocalizedError {
    case appointmentNotCompleted
    case duplicateFeedback
    case invalidRating
    case appointmentNotOwned
    case missingPatientId
    
    var errorDescription: String? {
        switch self {
        case .appointmentNotCompleted:
            return "Feedback can only be submitted for completed appointments"
        case .duplicateFeedback:
            return "You have already submitted feedback for this appointment"
        case .invalidRating:
            return "Please provide a valid rating"
        case .appointmentNotOwned:
            return "This appointment does not belong to you"
        case .missingPatientId:
            return "Patient information is missing"
        }
    }
}
