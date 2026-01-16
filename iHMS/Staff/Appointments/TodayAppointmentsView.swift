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
                    
                    Text(statusText)
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
    
    var isMissed: Bool {
        guard appointment.appointmentStatus != .completed &&
              appointment.appointmentStatus != .cancelled,
              let slot = appointment.timeSlot else { return false }
        
        // Parse time string "HH:mm:ss"
        let components = slot.endTime.split(separator: ":")
        guard components.count >= 2,
              let endHour = Int(components[0]),
              let endMinute = Int(components[1]) else { return false }
        
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        // Strict comparison: if current time > end time
        if currentHour > endHour { return true }
        if currentHour == endHour && currentMinute > endMinute { return true }
        
        return false
    }
    
    private var statusText: String {
        if isMissed { return "Missed" }
        return appointment.appointmentStatus.displayName
    }
    
    private var statusColor: Color {
        if isMissed { return .red }
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
