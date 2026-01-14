//
//  CreatePrescriptionView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI

struct CreatePrescriptionView: View {
    @StateObject private var viewModel: CreatePrescriptionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddMedicine = false
    @State private var showingFollowUpSheet = false
    
    init(patient: Patient, appointment: Appointment, staffId: UUID) {
        _viewModel = StateObject(wrappedValue: CreatePrescriptionViewModel(
            patient: patient,
            appointment: appointment,
            staffId: staffId
        ))
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
                    
                    // Follow-up
                    followUpSection
                }
                .padding()
            }
            .navigationTitle("Create Prescription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            if await viewModel.savePrescription() {
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
            .sheet(isPresented: $showingFollowUpSheet) {
                RecommendFollowUpSheet(
                    followUpDate: $viewModel.followUpDate,
                    followUpNotes: $viewModel.followUpNotes
                )
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
                    Text(viewModel.patient.initials)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            
            VStack(alignment: .leading) {
                Text(viewModel.patient.fullName)
                    .font(.headline)
                Text("Age: \(viewModel.patient.age) • \(viewModel.patient.gender ?? "N/A")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
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
            Text("Additional Notes")
                .font(.headline)
            
            TextField("Enter additional notes", text: $viewModel.notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(3...6)
        }
    }
    
    private var followUpSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Follow-up Appointment")
                .font(.headline)
            
            if let followUpDate = viewModel.followUpDate {
                // Show set follow-up
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.title3)
                            .foregroundColor(.green)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Follow-up Recommended")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(formatDate(followUpDate))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button(role: .destructive) {
                            viewModel.followUpDate = nil
                            viewModel.followUpNotes = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                    }
                    
                    if !viewModel.followUpNotes.isEmpty {
                        Text(viewModel.followUpNotes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Show add button
                Button {
                    showingFollowUpSheet = true
                } label: {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title3)
                        Text("Recommend Follow-up Date")
                            .fontWeight(.medium)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
