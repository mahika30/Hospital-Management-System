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
                        CompletedAppointmentRow(appointment: appointment)
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Completed Appointments")
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
                Label(appointment.appointmentDate, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let time = appointment.appointmentTime {
                    Label(time, systemImage: "clock")
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
