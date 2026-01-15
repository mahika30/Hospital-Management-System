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
                        NavigationLink {
                            PatientAppointmentDetailView(appointment: appointment)
                        } label: {
                            PastAppointmentRow(appointment: appointment)
                        }
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
        .padding(.vertical, 8)
    }
}
