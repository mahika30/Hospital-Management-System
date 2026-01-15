//
//  PatientFeedbackView.swift
//  iHMS
//
//  Created by Deepanshu Garg on 15/01/26.
//


//
//  PatientFeedbackView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct PatientFeedbackView: View {
    
    @StateObject private var viewModel: PatientFeedbackViewModel
    @Environment(\.dismiss) private var dismiss
    let onSuccess: () -> Void
    
    init(appointment: Appointment, patientId: UUID, onSuccess: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: PatientFeedbackViewModel(appointment: appointment, patientId: patientId))
        self.onSuccess = onSuccess
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Header Section
                        VStack(spacing: 12) {
                            Image(systemName: "star.bubble.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Rate Your Experience")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Your feedback helps us improve")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                        
                        // Star Rating Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("How was your appointment?")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 16) {
                                ForEach(1...5, id: \.self) { star in
                                    Image(systemName: star <= viewModel.rating ? "star.fill" : "star")
                                        .font(.system(size: 40))
                                        .foregroundColor(star <= viewModel.rating ? .yellow : Color(.systemGray4))
                                        .onTapGesture {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                                viewModel.rating = star
                                            }
                                        }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            
                            if viewModel.rating > 0 {
                                Text(ratingDescription)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Comments Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Additional Comments (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            ZStack(alignment: .topLeading) {
                                if viewModel.comments.isEmpty {
                                    Text("Share your experience with the doctor...")
                                        .foregroundColor(Color(.placeholderText))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 16)
                                }
                                
                                TextEditor(text: $viewModel.comments)
                                    .frame(height: 120)
                                    .padding(8)
                                    .scrollContentBackground(.hidden)
                                    .background(Color(.tertiarySystemGroupedBackground))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(20)
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
                        
                        // Submit Button
                        Button(action: {
                            Task {
                                await viewModel.submitFeedback()
                            }
                        }) {
                            HStack(spacing: 12) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    Text("Submit Feedback")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: viewModel.canSubmit ? [.blue, .blue.opacity(0.8)] : [.gray, .gray],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(14)
                            .shadow(color: viewModel.canSubmit ? .blue.opacity(0.3) : .clear, radius: 10, x: 0, y: 5)
                        }
                        .disabled(!viewModel.canSubmit)
                        .padding(.top, 10)
                        
                        if viewModel.rating == 0 {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle.fill")
                                    .font(.caption)
                                Text("Please select a rating to continue")
                                    .font(.caption)
                            }
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
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
                    onSuccess()
                    dismiss()
                }
            } message: {
                Text("Thank you for your feedback!")
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
    PatientFeedbackView(
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
            patient: nil,
            staff: Staff(
                id: UUID(),
                fullName: "Dr. John Smith",
                email: "john@example.com",
                departmentId: nil,
                designation: "Cardiologist",
                phone: nil,
                createdAt: nil
            ),
            timeSlot: nil
        ),
        patientId: UUID()
    )
}