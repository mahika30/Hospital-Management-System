//
//  DoctorFeedbackViewModel.swift
//  iHMS
//
//  Created by Deepanshu Garg on 15/01/26.
//


//
//  DoctorFeedbackViewModel.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class DoctorFeedbackViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var rating: Int = 0  // Optional for doctors
    @Published var comments: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSuccessAlert = false
    @Published var showErrorAlert = false
    
    // MARK: - Private Properties
    private let appointment: Appointment
    private let staffId: UUID
    private let feedbackService = FeedbackService()
    
    // MARK: - Initialization
    init(appointment: Appointment, staffId: UUID) {
        self.appointment = appointment
        self.staffId = staffId
    }
    
    // MARK: - Validation
    
    /// Check if the form can be submitted (doctors can submit without rating)
    var canSubmit: Bool {
        !isLoading && (rating == 0 || (rating >= 1 && rating <= 5))
    }
    
    /// Validate appointment status
    private func validateAppointment() throws {
        guard appointment.status.lowercased() == "completed" else {
            throw FeedbackError.appointmentNotCompleted
        }
    }
    
    /// Validate appointment belongs to this doctor
    private func validateOwnership() throws {
        guard appointment.staffId == staffId else {
            throw FeedbackError.appointmentNotOwned
        }
    }
    
    // MARK: - Feedback Submission
    
    /// Submit doctor feedback for the appointment
    func submitFeedback() async {
        guard canSubmit else {
            errorMessage = "Please check your input"
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
            
            // Validate ownership
            try validateOwnership()
            
            // Check for duplicate feedback
            let exists = try await feedbackService.checkFeedbackExists(
                appointmentId: appointment.id,
                submittedBy: .doctor
            )
            
            if exists {
                throw FeedbackError.duplicateFeedback
            }
            
            // Get patient ID from appointment
            guard let patientId = appointment.patient?.id ?? appointment.patientId as UUID? else {
                throw FeedbackError.missingPatientId
            }
            
            // Submit feedback (rating is optional for doctors)
            try await feedbackService.submitFeedback(
                appointmentId: appointment.id,
                patientId: patientId,
                doctorId: staffId,
                submittedBy: .doctor,
                rating: rating > 0 ? rating : nil,  // Only include rating if provided
                comments: comments.isEmpty ? nil : comments
            )
            
            // Show success
            showSuccessAlert = true
            
        } catch FeedbackError.duplicateFeedback {
            errorMessage = "You have already submitted feedback for this appointment"
            showErrorAlert = true
        } catch FeedbackError.appointmentNotCompleted {
            errorMessage = "Feedback can only be submitted for completed appointments"
            showErrorAlert = true
        } catch FeedbackError.appointmentNotOwned {
            errorMessage = "You can only submit feedback for your own appointments"
            showErrorAlert = true
        } catch FeedbackError.missingPatientId {
            errorMessage = "Unable to identify patient for this appointment"
            showErrorAlert = true
        } catch {
            errorMessage = "Failed to submit feedback: \(error.localizedDescription)"
            showErrorAlert = true
        }
        
        isLoading = false
    }
    
    /// Check if feedback already exists for this appointment
    func checkExistingFeedback() async -> Bool {
        do {
            return try await feedbackService.checkFeedbackExists(
                appointmentId: appointment.id,
                submittedBy: .doctor
            )
        } catch {
            print("Error checking existing feedback: \(error)")
            return false
        }
    }
}