//
//  MedicineRowView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct MedicineRowView: View {
    let medicine: MedicineInput
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(medicine.name)
                        .font(.headline)
                    Text(medicine.dosage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            
            HStack(spacing: 12) {
                Label(medicine.frequency, systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Label(medicine.duration, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            if !medicine.instructions.isEmpty {
                Text(medicine.instructions)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}
