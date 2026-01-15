//
//  DoctorFeedbackView.swift
//  iHMS
//
//  Created by Deepanshu Garg on 15/01/26.
//


//
//  DoctorFeedbackView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct DoctorFeedbackView: View {
    
    @StateObject private var viewModel: DoctorFeedbackViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(appointment: Appointment, staffId: UUID) {
        _viewModel = StateObject(wrappedValue: DoctorFeedbackViewModel(appointment: appointment, staffId: staffId))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header Section
                    VStack(spacing: 8) {
                        Image(systemName: "stethoscope.circle")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("Appointment Feedback")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Share your notes about this appointment")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Star Rating Section (Optional for doctors)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Rating (Optional)")
                                .font(.headline)
                            Spacer()
                            if viewModel.rating > 0 {
                                Button("Clear") {
                                    withAnimation {
                                        viewModel.rating = 0
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                                    .font(.system(size: 32))
                                    .foregroundColor(star <= viewModel.rating ? .yellow : .gray.opacity(0.3))
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            viewModel.rating = star
                                        }
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        
                        if viewModel.rating > 0 {
                            Text(ratingDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("You can skip rating and just add comments")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Comments Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Comments (Optional)")
                            .font(.headline)
                        
                        TextEditor(text: $viewModel.comments)
                            .frame(height: 120)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                        
                        Text("Add notes about the appointment, patient condition, or follow-up recommendations")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Submit Button
                    Button(action: {
                        Task {
                            await viewModel.submitFeedback()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "paperplane.fill")
                                Text("Submit Feedback")
                                    .fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(viewModel.canSubmit ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!viewModel.canSubmit)
                }
                .padding()
            }
            .navigationTitle("Give Feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Success", isPresented: $viewModel.showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Feedback submitted successfully!")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var ratingDescription: String {
        switch viewModel.rating {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
}

// MARK: - Preview

#Preview {
    DoctorFeedbackView(
        appointment: Appointment(
            id: UUID(),
            patientId: UUID(),
            staffId: UUID(),
            timeSlotId: nil,
            appointmentDate: "2026-01-10",
            appointmentTime: "10:00",
            status: "completed",
            reasonForVisit: "Regular checkup",
            notes: nil,
            createdAt: nil,
            updatedAt: nil,
            patient: Patient(
                id: UUID(),
                fullName: "John Doe",
                email: "john@example.com",
                phoneNumber: "1234567890",
                dateOfBirth: nil,
                gender: nil,
                createdAt: nil,
                bloodGroup: nil
            ),
            staff: nil,
            timeSlot: nil
        ),
        staffId: UUID()
    )
}

