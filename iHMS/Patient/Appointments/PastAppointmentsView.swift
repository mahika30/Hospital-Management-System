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
                        NavigationLink(destination: AppointmentDestinationView(appointment: appointment)) {
                            PastAppointmentRow(appointment: appointment)
                        }
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
            await viewModel.loadPastAppointments()
        }
    }
}

struct PastAppointmentRow: View {
    let appointment: Appointment
    
    var initials: String {
        let name = appointment.staff?.fullName ?? "Doc"
        let components = name.split(separator: " ")
        if let first = components.first?.first, let last = components.last?.first {
            return "\(first)\(last)".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var isMissed: Bool {
        let status = appointment.status.lowercased()
        // If it's in this list (past appointments) and not completed/cancelled, it's missed
        return status != "completed" && status != "cancelled"
    }
    
    var statusText: String {
        if isMissed {
            return "Missed"
        }
        return appointment.status.capitalized
    }
    
    var statusColor: Color {
        if isMissed {
            return .red
        }
        return appointment.appointmentStatus.color
    }

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.green)
                    .frame(width: 50, height: 50)
                
                Text(initials)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Name & Info
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.staff?.fullName ?? "Unknown Doctor")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // Using Date and Designation in place of Age/Gender line
                Text("\(appointment.formattedDate)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Time & Status
            VStack(alignment: .trailing, spacing: 4) {
                if let slot = appointment.timeSlot {
                    Text(slot.timeRange)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                } else if let time = appointment.appointmentTime {
                    Text(time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(statusText)
                    .font(.caption2)
                    .fontWeight(.bold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.2))
                    .foregroundColor(statusColor)
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 8)
    }
}
