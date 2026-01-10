//
//  DialogComponents.swift
//  iHMS
//
//  Created on 08/01/2026.
//

import SwiftUI

// MARK: - Emergency Cancellation Dialog
struct EmergencyCancellationDialog: View {
    let appointments: [Appointment]
    let onConfirm: (String) -> Void
    let onCancel: () -> Void
    
    @State private var cancellationReason = ""
    @State private var selectedReason: CancellationReasonOption = .emergency
    
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(redGradient)
                .frame(width: 70, height: 70)
                .blur(radius: 10)
            
            Circle()
                .fill(Color.red.opacity(0.15))
                .frame(width: 60, height: 60)
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 28))
                .foregroundStyle(redIconGradient)
                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
    
    private var redGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.2), Color.red.opacity(0.1)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private var redIconGradient: LinearGradient {
        LinearGradient(
            colors: [.red, .red.opacity(0.8)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private func appointmentRow(_ appointment: Appointment) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(patientIconGradient)
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                )
                .overlay(
                    Circle()
                        .stroke(Color.red.opacity(0.4), lineWidth: 1)
                )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(appointment.patient?.fullName ?? "Unknown Patient")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                if let reason = appointment.reasonForVisit {
                    Text(reason)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.red.opacity(0.6))
                .font(.caption)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(white: 0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
        )
    }
    
    private var patientIconGradient: LinearGradient {
        LinearGradient(
            colors: [Color.red.opacity(0.3), Color.red.opacity(0.15)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    headerIcon
                    
                    Text("Emergency Cancellation")
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    
                    Text("\(appointments.count) patient(s) will be notified")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            
                // Affected Patients
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Affected Appointments")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                    }
                    
                    ForEach(appointments) { appointment in
                        appointmentRow(appointment)
                    }
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            
            // Reason Selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Cancellation Reason")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                ForEach(CancellationReasonOption.allCases, id: \.self) { reason in
                    Button {
                        selectedReason = reason
                    } label: {
                        HStack {
                            Image(systemName: reason.icon)
                                .font(.body)
                                .foregroundStyle(reason.color)
                                .frame(width: 24)
                            
                            Text(reason.title)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            if selectedReason == reason {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(.green)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedReason == reason ? Color(white: 0.2) : Color(white: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedReason == reason ? Color.green.opacity(0.5) : Color.clear, lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                
                // Custom reason field
                if selectedReason == .other {
                    TextField("Enter reason", text: $cancellationReason)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(white: 0.15))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
            
                // Actions
                VStack(spacing: 12) {
                    Button {
                        let reason = selectedReason == .other ? cancellationReason : selectedReason.title
                        onConfirm(reason)
                    } label: {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text("Confirm Cancellation")
                        }
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.red, Color.red.opacity(0.85)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .red.opacity(0.4), radius: 12, x: 0, y: 6)
                        )
                    }
                    .disabled(selectedReason == .other && cancellationReason.isEmpty)
                    .opacity(selectedReason == .other && cancellationReason.isEmpty ? 0.5 : 1)
                    
                    Button {
                        onCancel()
                    } label: {
                        Text("Keep Appointments")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(.ultraThinMaterial)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                    }
                }
            }
            .padding(24)
        }
        .background(.ultraThinMaterial)
    }
}

enum CancellationReasonOption: String, CaseIterable {
    case emergency = "Medical Emergency"
    case illness = "Doctor Illness"
    case familyEmergency = "Family Emergency"
    case other = "Other Reason"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .emergency: return "cross.case.fill"
        case .illness: return "thermometer"
        case .familyEmergency: return "person.2.fill"
        case .other: return "text.alignleft"
        }
    }
    
    var color: Color {
        switch self {
        case .emergency: return .red
        case .illness: return .orange
        case .familyEmergency: return .purple
        case .other: return .blue
        }
    }
}

// MARK: - Running Late Dialog
struct RunningLateDialog: View {
    let onConfirm: (Int) -> Void
    let onCancel: () -> Void
    
    @State private var delayMinutes = 15
    
    var body: some View {
        VStack(spacing: 28) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.3), Color.yellow.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                        .blur(radius: 12)
                    
                    Circle()
                        .fill(Color.yellow.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .stroke(Color.yellow.opacity(0.4), lineWidth: 2)
                        )
                    
                    Image(systemName: "clock.badge.exclamationmark.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .yellow.opacity(0.9)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .yellow.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                
                Text("Running Late")
                    .font(.system(.title2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
                
                Text("Notify patients about delay")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 20)
            
            // Delay Selector
            VStack(spacing: 18) {
                HStack {
                    Image(systemName: "timer")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Expected Delay")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                
                HStack(spacing: 12) {
                    ForEach([15, 30, 45, 60], id: \.self) { minutes in
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                delayMinutes = minutes
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text("\(minutes)")
                                    .font(.system(.title2, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(delayMinutes == minutes ? .yellow : .primary)
                                
                                Text("min")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.medium)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 76)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(
                                        delayMinutes == minutes 
                                        ? LinearGradient(
                                            colors: [Color.yellow.opacity(0.25), Color.yellow.opacity(0.15)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        : LinearGradient(
                                            colors: [Color(white: 0.15), Color(white: 0.12)],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .stroke(
                                                delayMinutes == minutes ? Color.yellow.opacity(0.6) : Color.white.opacity(0.1), 
                                                lineWidth: delayMinutes == minutes ? 2 : 1
                                            )
                                    )
                                    .shadow(
                                        color: delayMinutes == minutes ? Color.yellow.opacity(0.3) : Color.clear,
                                        radius: 8,
                                        x: 0,
                                        y: 4
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Info
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(.blue)
                
                Text("Upcoming patients will receive notification about the delay")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.gray)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.blue.opacity(0.1))
            )
            
            // Actions
            VStack(spacing: 12) {
                Button {
                    onConfirm(delayMinutes)
                } label: {
                    HStack {
                        Image(systemName: "bell.badge.fill")
                        Text("Notify Patients")
                    }
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.yellow.opacity(0.9)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .yellow.opacity(0.5), radius: 12, x: 0, y: 6)
                    )
                }
                
                Button {
                    onCancel()
                } label: {
                    Text("Cancel")
                        .font(.system(.body, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        )
                }
            }
        }
        .padding(28)
        .background(.ultraThinMaterial)
    }
}
