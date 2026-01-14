//
//  ConsultationView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI
import Supabase

struct ConsultationView: View {
    let appointment: Appointment
    let patient: Patient
    let staffId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreatePrescription = false
    @State private var showingCompletionAlert = false
    @State private var isCompleting = false
    @State private var hasStarted = false
    @State private var prescription: Prescription?
    @State private var isLoadingPrescription = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Patient Info Card
                patientInfoCard
                
                // Medical Information
                medicalInfoSection
                
                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .onAppear {
            print("🏥 ConsultationView appeared")
            print("🏥 Patient: \(patient.fullName)")
            print("🏥 Appointment: \(appointment.id)")
            Task {
                await loadPrescription()
            }
        }
        .navigationTitle("Consultation")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingCreatePrescription, onDismiss: {
            // Reload prescription after dismissing create/edit sheet
            Task {
                await loadPrescription()
            }
        }) {
            CreatePrescriptionView(
                patient: patient,
                appointment: appointment,
                staffId: staffId,
                existingPrescription: prescription
            )
        }
        .alert("Complete Consultation", isPresented: $showingCompletionAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Complete") {
                Task {
                    await completeConsultation()
                }
            }
        } message: {
            Text("Mark this consultation as completed?")
        }
    }
    
    private var patientInfoCard: some View {
        VStack(spacing: 20) {
            // Status Badge
            HStack {
                Spacer()
                Text(appointment.appointmentStatus.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(appointment.appointmentStatus.color.opacity(0.2))
                    .foregroundColor(appointment.appointmentStatus.color)
                    .cornerRadius(20)
            }
            
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 100, height: 100)
                .overlay {
                    Text(patient.initials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            VStack(spacing: 8) {
                Text(patient.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                HStack(spacing: 20) {
                    Label("\(patient.age)y", systemImage: "person.fill")
                    Label(patient.gender ?? "N/A", systemImage: "figure.stand")
                    if let bloodGroup = patient.bloodGroup {
                        Label(bloodGroup, systemImage: "drop.fill")
                    }
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            if let slot = appointment.timeSlot {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(.blue)
                    Text(slot.timeRange)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    private var medicalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Medical Information")
                .font(.headline)
            
            // Show existing prescription if loaded
            if let prescription = prescription {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.green)
                        Text("Prescription on File")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                        Spacer()
                    }
                    
                    if let diagnosis = prescription.diagnosis {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Diagnosis:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(diagnosis)
                                .font(.subheadline)
                        }
                    }
                    
                    if let medicines = prescription.medicines, !medicines.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Medicines: \(medicines.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(medicines.prefix(2)) { med in
                                Text("• \(med.medicineName) - \(med.dosage)")
                                    .font(.caption)
                            }
                            if medicines.count > 2 {
                                Text("... and \(medicines.count - 2) more")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
            
            if let allergies = patient.allergies, !allergies.isEmpty {
                MedicalInfoCard(
                    title: "Allergies",
                    items: allergies,
                    icon: "exclamationmark.triangle.fill",
                    color: .red
                )
            }
            
            if let medications = patient.currentMedications, !medications.isEmpty {
                MedicalInfoCard(
                    title: "Current Medications",
                    items: medications,
                    icon: "pills.fill",
                    color: .blue
                )
            }
            
            if let history = patient.medicalHistory, !history.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Medical History", systemImage: "doc.text.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    
                    Text(history)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }
            
            if let phone = patient.phoneNumber {
                HStack {
                    Label("Contact", systemImage: "phone.fill")
                        .font(.subheadline)
                        .foregroundColor(.green)
                    Spacer()
                    Text(phone)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Start Consultation (only show if not started and not completed)
            if !hasStarted && appointment.appointmentStatus != .completed && appointment.appointmentStatus != .cancelled {
                Button {
                    hasStarted = true
                } label: {
                    HStack {
                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                        Text("Start Consultation")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.orange, Color.orange.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            // Add/Update Prescription (show after starting or if completed)
            if hasStarted || appointment.appointmentStatus == .completed {
                Button {
                    showingCreatePrescription = true
                } label: {
                    HStack {
                        Image(systemName: prescription != nil ? "doc.text.badge.plus" : "doc.text.fill")
                            .font(.title3)
                        Text(prescription != nil ? "Update Prescription" : "Add Prescription")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: prescription != nil ? [Color.green, Color.green.opacity(0.8)] : [Color.blue, Color.blue.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: (prescription != nil ? Color.green : Color.blue).opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            
            // Complete Consultation (show after starting and not completed)
            if hasStarted && appointment.appointmentStatus != .completed && appointment.appointmentStatus != .cancelled {
                Button {
                    showingCompletionAlert = true
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                        Text("Complete Consultation")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.green, Color.green.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isCompleting)
            }
        }
    }
    
    private func completeConsultation() async {
        isCompleting = true
        
        do {
            struct StatusUpdate: Encodable {
                let status: String
            }
            
            try await SupabaseManager.shared.client
                .from("appointments")
                .update(StatusUpdate(status: "completed"))
                .eq("id", value: appointment.id.uuidString)
                .execute()
            
            dismiss()
        } catch {
            print("Error completing consultation: \(error)")
        }
        
        isCompleting = false
    }
    
    private func loadPrescription() async {
        isLoadingPrescription = true
        
        do {
            print("🔍 [Doctor] Loading prescription for appointment: \(appointment.id)")
            let response: [Prescription] = try await SupabaseManager.shared.client
                .from("prescriptions")
                .select("""
                    *,
                    prescription_medicines(
                        id,
                        prescription_id,
                        medicine_name,
                        dosage,
                        frequency,
                        duration,
                        instructions
                    )
                """)
                .eq("appointment_id", value: appointment.id.uuidString)
                .execute()
                .value
            
            prescription = response.first
            if prescription != nil {
                print("✅ [Doctor] Prescription loaded: \(prescription!.id)")
                print("   Diagnosis: \(prescription!.diagnosis ?? "none")")
                print("   Medicines: \(prescription!.medicines?.count ?? 0)")
            } else {
                print("⚠️ [Doctor] No prescription found")
            }
        } catch {
            print("❌ [Doctor] Error loading prescription: \(error)")
        }
        
        isLoadingPrescription = false
    }
}
private struct MedicalInfoCard: View {
    let title: String
    let items: [String]
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            ForEach(items, id: \.self) { item in
                Text("• \(item)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}
