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
            HStack {
                Image(systemName: "pills.circle.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.medicineName)
                        .font(.headline)
                    Text(medicine.dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("Frequency", systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(medicine.frequency)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                HStack {
                    Label("Duration", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(medicine.duration)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            if let instructions = medicine.instructions, !instructions.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Instructions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(instructions)
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
