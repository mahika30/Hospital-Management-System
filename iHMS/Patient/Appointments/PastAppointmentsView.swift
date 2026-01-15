//
//  PastAppointmentsView.swift
//  iHMS
//
//  Created on 12/01/2026.
//

import SwiftUI

struct PastAppointmentsView: View {
    @StateObject private var viewModel: PastAppointmentsViewModel
    
    init(patientId: UUID) {
        _viewModel = StateObject(wrappedValue: PastAppointmentsViewModel(patientId: patientId))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Loading past appointments...")
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
                            await viewModel.loadPastAppointments()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if viewModel.appointments.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("No Past Appointments")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Your completed and past appointments will appear here")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.appointments) { appointment in
                        PastAppointmentRow(appointment: appointment, patientId: viewModel.patientId)
                    }
                }
                .listStyle(.insetGrouped)
                .refreshable {
                    await viewModel.loadPastAppointments()
                }
            }
        }
        .navigationTitle("Past Appointments")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await viewModel.refreshAppointments()
        }
        .task {
            await viewModel.loadPastAppointments()
        }
    }
}

struct PastAppointmentRow: View {
    let appointment: Appointment
    let patientId: UUID
    
    @State private var showFeedbackSheet = false
    @State private var hasFeedback = false
    
    var statusColor: Color {
        switch appointment.status.lowercased() {
        case "completed":
            return .green
        case "cancelled":
            return .red
        default:
            return .gray
        }
    }
    
    var statusIcon: String {
        switch appointment.status.lowercased() {
        case "completed":
            return "checkmark.circle.fill"
        case "cancelled":
            return "xmark.circle.fill"
        default:
            return "clock.fill"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink {
                PatientAppointmentDetailView(appointment: appointment)
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(appointment.staff?.fullName ?? "Unknown Doctor")
                                .font(.headline)
                            
                            if let designation = appointment.staff?.designation {
                                Text(designation)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: statusIcon)
                                .font(.caption)
                            Text(appointment.status.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(statusColor.opacity(0.1))
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
                }
            }
            
            // Feedback Button - Show for all past appointments unless cancelled
            if appointment.status.lowercased() != "cancelled" && !hasFeedback {
                Button(action: {
                    showFeedbackSheet = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                        Text("Rate Appointment")
                            .fontWeight(.semibold)
                    }
                    .font(.subheadline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            colors: [.blue.opacity(0.1), .purple.opacity(0.1)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                LinearGradient(
                                    colors: [.blue.opacity(0.3), .purple.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            
            // Show feedback submitted indicator
            if hasFeedback {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                    Text("Feedback Submitted")
                        .fontWeight(.semibold)
                }
                .font(.subheadline)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green.opacity(0.12))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showFeedbackSheet) {
            PatientFeedbackView(appointment: appointment, patientId: patientId) {
                // Mark as submitted immediately
                hasFeedback = true
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
                submittedBy: .patient
            )
        } catch {
            print("Error checking feedback status: \(error)")
        }
    }
}
