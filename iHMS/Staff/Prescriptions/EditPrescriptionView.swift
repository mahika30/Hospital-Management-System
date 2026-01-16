//
//  EditPrescriptionView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct EditPrescriptionView: View {
    @StateObject private var viewModel: EditPrescriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMedicine = false
    
    init(prescription: Prescription) {
        _viewModel = StateObject(wrappedValue: EditPrescriptionViewModel(prescription: prescription))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Patient Info Card
                    patientInfoCard
                    
                    // Diagnosis
                    diagnosisSection
                    
                    // Medicines List
                    medicinesSection
                    
                    // Notes
                    notesSection
                }
                .padding()
            }
            .navigationTitle("Edit Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Update") {
                        Task {
                            if await viewModel.updatePrescription() {
                                dismiss()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading || viewModel.medicines.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddMedicine) {
                AddMedicineSheet { medicine in
                    viewModel.addMedicine(medicine)
                    showingAddMedicine = false
                }
            }
            .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
                Button("OK") {
                    viewModel.errorMessage = nil
                }
            } message: {
                if let error = viewModel.errorMessage {
                    Text(error)
                }
            }
        }
    }
    
    private var patientInfoCard: some View {
        HStack {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    if let patient = viewModel.prescription.patient {
                        Text(patient.initials)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
            
            VStack(alignment: .leading) {
                if let patient = viewModel.prescription.patient {
                    Text(patient.fullName)
                        .font(.headline)
                    Text("Age: \(patient.age) • \(patient.gender ?? "N/A")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text(viewModel.prescription.prescriptionDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var diagnosisSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diagnosis")
                .font(.headline)
            
            TextField("Enter diagnosis", text: $viewModel.diagnosis, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    private var medicinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Medicines")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    showingAddMedicine = true
                } label: {
                    Label("Add", systemImage: "plus.circle.fill")
                        .font(.subheadline)
                }
            }
            
            if viewModel.medicines.isEmpty {
                Text("No medicines added yet")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                ForEach(Array(viewModel.medicines.enumerated()), id: \.element.id) { index, medicine in
                    MedicineRowView(medicine: medicine) {
                        viewModel.removeMedicine(at: index)
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Internal Notes")
                .font(.headline)
            
            TextField("Enter internal notes (doctor only)", text: $viewModel.notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
}
