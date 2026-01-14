//
//  MedicineCard.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct MedicineCard: View {
    let medicine: PrescriptionMedicine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Medicine Header
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: "pills.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(medicine.medicineName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text(medicine.dosage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fontWeight(.medium)
                }
                
                Spacer()
            }
            
            // Medicine Details
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Frequency")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(medicine.frequency)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(medicine.duration)
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
            }
            
            // Instructions (if available)
            if let instructions = medicine.instructions, !instructions.isEmpty {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    
                    Text(instructions)
                        .font(.caption2)
                        .foregroundColor(.primary)
                        .lineSpacing(3)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.orange.opacity(0.08))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
