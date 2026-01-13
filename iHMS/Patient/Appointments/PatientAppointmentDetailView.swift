//
//  PatientAppointmentDetailView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI
import Supabase
import Combine

@MainActor
class PatientAppointmentDetailViewModel: ObservableObject {
    @Published var prescription: Prescription?
    @Published var isLoadingPrescription = false
    @Published var errorMessage: String?
    
    func loadPrescription(appointmentId: UUID) async {
        isLoadingPrescription = true
        errorMessage = nil
        
        do {
            print("🔍 Loading prescription for appointment: \(appointmentId)")
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
                .eq("appointment_id", value: appointmentId.uuidString)
                .execute()
                .value
            
            prescription = response.first
            if prescription != nil {
                print("✅ Prescription loaded successfully")
            } else {
                print("⚠️ No prescription found for this appointment")
            }
        } catch {
            print("❌ Error loading prescription: \(error)")
            errorMessage = "Failed to load prescription: \(error.localizedDescription)"
        }
        
        isLoadingPrescription = false
    }
}

struct PatientAppointmentDetailView: View {
    let appointment: Appointment
    @StateObject private var viewModel = PatientAppointmentDetailViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Appointment Info
                appointmentInfoCard
                
                // Doctor Info
                if let staff = appointment.staff {
                    doctorInfoCard(staff)
                }
                
                // Prescription Section
                prescriptionSection
            }
            .padding()
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPrescription(appointmentId: appointment.id)
        }
    }
    
    private var appointmentInfoCard: some View {
        VStack(spacing: 20) {
            // Status Badge - Prominent at top
            VStack(spacing: 8) {
                Image(systemName: statusIcon)
                    .font(.system(size: 48))
                    .foregroundColor(statusColor)
                Text(appointment.appointmentStatus.displayName)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(statusColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(statusColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
            )
            
            // Date and Time Info
            VStack(spacing: 12) {
                HStack {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(appointment.formattedDate)
                                .font(.headline)
                        }
                    } icon: {
                        Image(systemName: "calendar")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                if let slot = appointment.timeSlot {
                    HStack {
                        Label {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(slot.timeRange)
                                    .font(.headline)
                            }
                        } icon: {
                            Image(systemName: "clock")
                                .font(.title3)
                                .foregroundColor(.blue)
                        }
                        Spacer()
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
            }
            
            // Show consultation status message
            if appointment.appointmentStatus == .inProgress || appointment.appointmentStatus == .confirmed {
                HStack {
                    Image(systemName: "stethoscope")
                        .foregroundColor(.orange)
                    Text("Consultation in progress...")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
            } else if appointment.appointmentStatus == .completed {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Consultation completed")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private var statusIcon: String {
        switch appointment.appointmentStatus {
        case .scheduled: return "calendar.badge.clock"
        case .confirmed: return "checkmark.seal.fill"
        case .inProgress: return "stethoscope"
        case .completed: return "checkmark.circle.fill"
        case .cancelled: return "xmark.circle.fill"
        case .noShow: return "exclamationmark.triangle.fill"
        case .rescheduled: return "arrow.triangle.2.circlepath"
        }
    }
    
    private func doctorInfoCard(_ staff: Staff) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.gradient)
                .frame(width: 50, height: 50)
                .overlay {
                    Text(staff.initials)
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Dr. \(staff.fullName)")
                    .font(.headline)
                if let specialization = staff.specialization {
                    Text(specialization)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var prescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prescription")
                .font(.headline)
            
            if viewModel.isLoadingPrescription {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if let prescription = viewModel.prescription {
                prescriptionContent(prescription)
            } else {
                noPrescriptionView
            }
        }
    }
    
    private func prescriptionContent(_ prescription: Prescription) -> some View {
        VStack(spacing: 16) {
            // Diagnosis
            if let diagnosis = prescription.diagnosis {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Diagnosis", systemImage: "stethoscope")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(diagnosis)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Medicines
            if let medicines = prescription.medicines, !medicines.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Prescribed Medicines", systemImage: "pills.fill")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(medicines) { medicine in
                        MedicineCard(medicine: medicine)
                    }
                }
            }
            
            // Notes
            if let notes = prescription.notes {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Additional Notes", systemImage: "note.text")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(notes)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Follow-up
            if let followUpDate = prescription.followUpDate {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Follow-up Appointment Recommended", systemImage: "calendar.badge.checkmark")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Recommended Date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatFollowUpDate(followUpDate))
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        Spacer()
                    }
                    
                    if let notes = prescription.followUpNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Doctor's Notes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                        .padding(.top, 4)
                    }
                    
                    Text("Please schedule your follow-up appointment")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
                )
            }
        }
    }
    
    private var noPrescriptionView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            Text("No Prescription")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("The doctor hasn't added a prescription for this appointment yet")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statusColor: Color {
        switch appointment.appointmentStatus {
        case .scheduled, .confirmed:
            return .blue
        case .inProgress:
            return .orange
        case .completed:
            return .green
        case .cancelled:
            return .red
        case .noShow:
            return .gray
        case .rescheduled:
            return .purple
        }
    }
    
    private func formatFollowUpDate(_ dateString: String) -> String {
        // Parse the ISO date string
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withFullDate]
        
        guard let date = isoFormatter.date(from: dateString) else {
            return dateString
        }
        
        // Format to readable date
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
