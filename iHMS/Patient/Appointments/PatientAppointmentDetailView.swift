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
            VStack(spacing: 14) {
                // Combined Appointment Info Card
                appointmentInfoCard
                
                // Prescription Section
                prescriptionSection
            }
            .padding(16)
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadPrescription(appointmentId: appointment.id)
        }
    }
    
    private var appointmentInfoCard: some View {
        VStack(spacing: 0) {
            // Doctor Info at top
            if let staff = appointment.staff {
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Text(staff.initials)
                                .foregroundColor(.white)
                                .font(.system(size: 20, weight: .bold))
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Dr. \(staff.fullName)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        if let specialization = staff.specialization {
                            Text(specialization)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(20)
            }
            
            Divider()
                .padding(.horizontal, 20)
            
            // Status, Date and Time in one section
            VStack(spacing: 14) {
                // Status Badge
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    Text(appointment.appointmentStatus.displayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(statusColor)
                    
                    Spacer()
                }
                
                // Date and Time Info in one line
                HStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar")
                            .font(.system(size: 15))
                            .foregroundColor(.accentColor)
                        
                        Text(appointment.formattedDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(.systemGray6))
                    )
                    
                    if let slot = appointment.timeSlot {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: 15))
                                .foregroundColor(.accentColor)
                            
                            Text(slot.timeRange)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.systemGray6))
                        )
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
    
    private var prescriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Prescription")
                .font(.headline)
                .fontWeight(.bold)
            
            if viewModel.isLoadingPrescription {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
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
                    HStack(spacing: 8) {
                        Image(systemName: "pills.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.blue)
                        
                        Text("Prescribed Medicines")
                            .font(.subheadline)
                            .fontWeight(.bold)
                    }
                    
                    ForEach(medicines) { medicine in
                        MedicineCard(medicine: medicine)
                    }
                }
            }
            
            // Follow-up
            if let followUpDate = prescription.followUpDate {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "calendar.badge.checkmark")
                            .font(.system(size: 14))
                            .foregroundColor(.green)
                        
                        Text("Follow-up Recommended")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Recommended Date")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(formatFollowUpDate(followUpDate))
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    if let notes = prescription.followUpNotes, !notes.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Doctor's Notes")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(notes)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Text("Please schedule your follow-up appointment")
                        .font(.caption2)
                        .foregroundColor(.green.opacity(0.8))
                        .padding(.top, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.25), lineWidth: 1)
                )
            }
        }
    }
    
    private var noPrescriptionView: some View {
        VStack(spacing: 14) {
            Image(systemName: appointment.appointmentStatus == .scheduled ? "calendar.badge.clock" : "doc.text")
                .font(.system(size: 52))
                .foregroundColor(.secondary)
            
            Text(appointment.appointmentStatus == .scheduled ? "Appointment Not Started Yet" : "No Prescription")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(appointment.appointmentStatus == .scheduled ? "The prescription will be available after your appointment" : "The doctor hasn't added a prescription for this appointment yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .padding(.horizontal, 20)
        .background(Color(.systemGray6))
        .cornerRadius(16)
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
