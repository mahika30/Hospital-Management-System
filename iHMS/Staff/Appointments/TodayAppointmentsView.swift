//
//  TodayAppointmentsView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct TodayAppointmentsView: View {
    @StateObject private var viewModel: TodayAppointmentsViewModel
    @State private var selectedAppointment: Appointment?
    @State private var showingConsultation = false
    
    init(staffId: UUID) {
        _viewModel = StateObject(wrappedValue: TodayAppointmentsViewModel(staffId: staffId))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.appointments.isEmpty {
                emptyState
            } else {
                appointmentsList
            }
        }
        .navigationTitle("Today's Appointments")
        .task {
            await viewModel.loadTodayAppointments()
        }
        .refreshable {
            await viewModel.loadTodayAppointments()
        }
        .sheet(item: $selectedAppointment) { appointment in
            NavigationStack {
                if let patient = appointment.patient {
                    ConsultationView(
                        appointment: appointment,
                        patient: patient,
                        staffId: viewModel.staffId
                    )
                }
            }
        }
    }
    
    private var appointmentsList: some View {
        List(viewModel.appointments) { appointment in
            TodayAppointmentRow(appointment: appointment)
                .onTapGesture {
                    print("📱 Tapped appointment: \(appointment.id)")
                    print("📱 Has patient: \(appointment.patient != nil)")
                    if let patient = appointment.patient {
                        print("📱 Patient name: \(patient.fullName)")
                        selectedAppointment = appointment
                    } else {
                        print("⚠️ No patient data for appointment")
                    }
                }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.checkmark")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Appointments Today")
                .font(.title2)
                .fontWeight(.semibold)
            Text("You have no scheduled appointments for today")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

struct TodayAppointmentRow: View {
    let appointment: Appointment
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(statusColor.gradient)
                    .frame(width: 50, height: 50)
                    .overlay {
                        if let patient = appointment.patient {
                            Text(patient.initials)
                                .foregroundColor(.white)
                                .fontWeight(.semibold)
                        }
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    if let patient = appointment.patient {
                        Text(patient.fullName)
                            .font(.headline)
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
                    
                    Text(appointment.appointmentStatus.displayName)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.2))
                        .foregroundColor(statusColor)
                        .cornerRadius(6)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var statusColor: Color {
        switch appointment.appointmentStatus {
        case .scheduled, .confirmed:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .cancelled:
            return .red
        case .noShow:
            return .gray
        case .rescheduled:
            return .purple
        }
    }
}
