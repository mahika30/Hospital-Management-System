//
//  AddMedicineSheet.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct AddMedicineSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (MedicineInput) -> Void
    
    @State private var name = ""
    @State private var dosage = ""
    @State private var frequency = "Once daily"
    @State private var duration = "7 days"
    @State private var instructions = ""
    
    let frequencyOptions = ["Once daily", "Twice daily", "Three times daily", "Four times daily", "As needed"]
    let durationOptions = ["3 days", "5 days", "7 days", "10 days", "14 days", "21 days", "30 days"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Medicine Details") {
                    TextField("Medicine Name", text: $name)
                    TextField("Dosage (e.g., 500mg)", text: $dosage)
                }
                
                Section("Timing") {
                    Picker("Frequency", selection: $frequency) {
                        ForEach(frequencyOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    
                    Picker("Duration", selection: $duration) {
                        ForEach(durationOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                }
                
                Section("Instructions") {
                    TextField("Special instructions (optional)", text: $instructions, axis: .vertical)
                        .lineLimit(3...5)
                }
            }
            .navigationTitle("Add Medicine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        let medicine = MedicineInput(
                            name: name,
                            dosage: dosage,
                            frequency: frequency,
                            duration: duration,
                            instructions: instructions
                        )
                        onAdd(medicine)
                    }
                    .disabled(name.isEmpty || dosage.isEmpty)
                }
            }
        }
    }
}
