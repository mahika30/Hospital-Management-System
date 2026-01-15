//
//  CompletedAppointmentsView.swift
//  iHMS
//
//  Created on 12/01/2026.
//

import SwiftUI

struct CompletedAppointmentsView: View {
    @StateObject private var viewModel: CompletedAppointmentsViewModel
    
    init(staffId: UUID) {
        _viewModel = StateObject(wrappedValue: CompletedAppointmentsViewModel(staffId: staffId))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading completed appointments...")
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    Text(errorMessage)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                    Button("Retry") {
                        Task {
                            await viewModel.loadCompletedAppointments()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if viewModel.appointments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.badge.questionmark")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("No Completed Appointments")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Your completed appointments will appear here")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.appointments) { appointment in
                        CompletedAppointmentRow(appointment: appointment, staffId: viewModel.staffId)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Past Appointments")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refreshAppointments()
        }
        .task {
            await viewModel.loadCompletedAppointments()
        }
    }
}

struct CompletedAppointmentRow: View {
    let appointment: Appointment
    let staffId: UUID
    
    @State private var showFeedbackSheet = false
    @State private var hasFeedback = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(Color.green.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        if let patient = appointment.patient {
                            Text(patient.initials)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        } else {
                            Text("?")
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.patient?.fullName ?? "Unknown Patient")
                        .font(.headline)
                    if let patient = appointment.patient {
                        Text("Age: \(patient.age) • \(patient.gender ?? "N/A")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if let slot = appointment.timeSlot {
                        Text(slot.timeRange)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    Text("Completed")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(6)
                }
            }
            
            if let reason = appointment.reasonForVisit {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            if let bloodGroup = appointment.patient?.bloodGroup {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("Blood Type: \(bloodGroup)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            
            // Feedback Button - Only show if feedback not submitted
            if !hasFeedback {
                Button(action: {
                    showFeedbackSheet = true
                }) {
                    HStack {
                        Image(systemName: "note.text.badge.plus")
                        Text("Give Feedback")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .padding(.top, 4)
            }
            
            // Show feedback submitted indicator
            if hasFeedback {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Feedback Submitted")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showFeedbackSheet) {
            DoctorFeedbackView(appointment: appointment, staffId: staffId)
                .onDisappear {
                    // Refresh feedback status after sheet dismissal
                    Task {
                        await checkFeedbackStatus()
                    }
                }
        }
        .task {
            await checkFeedbackStatus()
        }
    }
    
    // Check if feedback already exists
    private func checkFeedbackStatus() async {
        let feedbackService = FeedbackService()
        do {
            hasFeedback = try await feedbackService.checkFeedbackExists(
                appointmentId: appointment.id,
                submittedBy: .doctor
            )
        } catch {
            print("Error checking feedback status: \(error)")
        }
    }
}

private struct CompletedAppointmentDateRow: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appointment.patient?.fullName ?? "Unknown Patient")
                        .font(.headline)
                    
                    if let phone = appointment.patient?.phoneNumber {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                    Text("Completed")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            HStack(spacing: 16) {
                Label(appointment.formattedDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let slot = appointment.timeSlot {
                    Label(slot.timeRange, systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            if let reason = appointment.reasonForVisit {
                Text(reason)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
            
            if let bloodGroup = appointment.patient?.bloodGroup {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                    Text("Blood Type: \(bloodGroup)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
        }
        .padding(.vertical, 8)
    }
}
