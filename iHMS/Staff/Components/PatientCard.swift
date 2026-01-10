//
//  PatientCard.swift
//  iHMS
//
//  Created on 08/01/2026.
//

import SwiftUI

struct PatientCard: View {
    let patient: Patient
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Profile Avatar
                Circle()
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(patient.initials)
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                    )
                    .shadow(color: gradientColors[0].opacity(0.5), radius: 10, x: 0, y: 5)
                
                // Patient Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(patient.fullName)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    HStack(spacing: 12) {
                        if let mrn = patient.medicalRecordNumber {
                            Label(mrn, systemImage: "number")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.gray)
                        }
                        
                        if let status = patient.admissionStatus, let admissionStatusEnum = AdmissionStatus(rawValue: status) {
                            StatusBadge(status: admissionStatusEnum)
                        }
                    }
                    
                    if let phone = patient.phoneNumber {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill")
                                .font(.caption2)
                            Text(phone)
                                .font(.system(.caption, design: .rounded))
                        }
                        .foregroundStyle(.gray)
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.gray)
                    
                    if let statusStr = patient.admissionStatus,
                       statusStr == "Admitted",
                       let admissionDate = patient.admissionDate {
                        Text(daysAdmitted(from: admissionDate))
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(.gray)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(white: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 12, x: 0, y: 6)
            )
        }
        .buttonStyle(.plain)
    }
    
    private var gradientColors: [Color] {
        guard let statusStr = patient.admissionStatus,
              let status = AdmissionStatus(rawValue: statusStr) else {
            return [Color.blue, Color.blue.opacity(0.7)]
        }
        
        switch status {
        case .admitted:
            return [Color.green, Color.green.opacity(0.7)]
        case .outpatient:
            return [Color.blue, Color.blue.opacity(0.7)]
        case .discharged:
            return [Color.gray, Color.gray.opacity(0.7)]
        case .emergency:
            return [Color.red, Color.red.opacity(0.7)]
        }
    }
    
    private func daysAdmitted(from date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: date, to: Date()).day ?? 0
        return "\(days)d"
    }
}

struct StatusBadge: View {
    let status: AdmissionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.icon)
                .font(.system(size: 9))
            Text(status.rawValue)
                .font(.system(.caption2, design: .rounded))
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(statusColor.opacity(0.2))
        )
        .foregroundStyle(statusColor)
    }
    
    private var statusColor: Color {
        switch status {
        case .admitted: return .green
        case .outpatient: return .blue
        case .discharged: return .gray
        case .emergency: return .red
        }
    }
}
