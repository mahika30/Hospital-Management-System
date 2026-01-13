//
//  PrescriptionDetailView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI
import Supabase

struct PrescriptionDetailView: View {
    let prescription: Prescription
    @State private var doctorName: String = "Loading..."
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                headerCard
                
                // Diagnosis
                if let diagnosis = prescription.diagnosis {
                    diagnosisCard(diagnosis)
                }
                
                // Medicines
                medicinesSection
                
                // Notes
                if let notes = prescription.notes {
                    notesCard(notes)
                }
                
                // Follow-up
                if let followUpDate = prescription.followUpDate {
                    followUpCard(followUpDate, notes: prescription.followUpNotes)
                }
            }
            .padding()
        }
        .navigationTitle("Prescription Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDoctorName()
        }
    }
    
    private func loadDoctorName() async {
        do {
            struct StaffResponse: Decodable {
                let full_name: String
            }
            
            let response: [StaffResponse] = try await SupabaseManager.shared.client
                .from("staff")
                .select("full_name")
                .eq("id", value: prescription.staffId.uuidString)
                .execute()
                .value
            
            if let staff = response.first {
                doctorName = "Dr. \(staff.full_name)"
            } else {
                doctorName = "Doctor"
            }
        } catch {
            print("❌ Error loading doctor name: \(error)")
            doctorName = "Doctor"
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.blue)
                        Text(doctorName)
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text(formatDate(prescription.prescriptionDate))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func diagnosisCard(_ diagnosis: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Diagnosis", systemImage: "stethoscope")
                .font(.headline)
            
            Text(diagnosis)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var medicinesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Medicines", systemImage: "pills.fill")
                .font(.headline)
            
            if let medicines = prescription.medicines {
                ForEach(medicines) { medicine in
                    MedicineCard(medicine: medicine)
                }
            }
        }
    }
    
    private func notesCard(_ notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Additional Notes", systemImage: "note.text")
                .font(.headline)
            
            Text(notes)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func followUpCard(_ date: String, notes: String?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Follow-up Appointment", systemImage: "calendar.badge.clock")
                .font(.headline)
                .foregroundColor(.green)
            
            Text("Recommended Date: \(date)")
                .font(.subheadline)
            
            if let notes = notes {
                Text(notes)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
}
