import SwiftUI
import Supabase

@MainActor
struct PatientDetailView: View {
    let patient: Patient
    let viewModel: PatientSearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var appointments: [Appointment] = []
    @State private var isLoadingAppointments = false
    @State private var currentStaffId: UUID?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Patient Header
                PatientHeaderSection(patient: patient)
                
                // Quick Stats
                QuickStatsSection(patient: patient, appointments: appointments)
                
                // Medical Information
                ExpandableMedicalHistoryCard(patient: patient)
                
                // Contact Information
                ContactInformationSection(patient: patient)
                
                // Admission Information
                if patient.admissionStatus != nil {
                    AdmissionInformationSection(patient: patient)
                }
                
                // Recent Appointments

                if let staffId = currentStaffId {
                    RecentAppointmentsSection(
                        appointments: appointments,
                        isLoading: isLoadingAppointments,
                        patient: patient,
                        staffId: staffId
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Patient Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCurrentUser()
            await loadAppointments()
        }
    }
    
    private func loadCurrentUser() async {
        if let user = try? await SupabaseManager.shared.client.auth.session.user {
            currentStaffId = user.id
        }
    }
    
    private func loadAppointments() async {
        isLoadingAppointments = true
        appointments = await viewModel.getPatientAppointments(patient.id)
        isLoadingAppointments = false
    }
}

// MARK: - Patient Header Section
private struct PatientHeaderSection: View {
    let patient: Patient
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 100, height: 100)
                .overlay {
                    Text(patient.initials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                }
            
            // Name and MRN
            VStack(spacing: 4) {
                Text(patient.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let mrn = patient.medicalRecordNumber {
                    Text("MRN: \(mrn)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Status Badge
            if let admissionStatus = patient.admissionStatus,
               let status = AdmissionStatus(rawValue: admissionStatus) {
                HStack(spacing: 6) {
                    Image(systemName: status.icon)
                        .font(.caption)
                    
                    Text(status.rawValue.capitalized)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(status.color.opacity(0.2))
                )
                .foregroundStyle(status.color)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
        )
    }
    
    private var gradientColors: [Color] {
        if let status = patient.admissionStatus,
           let admissionStatus = AdmissionStatus(rawValue: status) {
            return [admissionStatus.color, admissionStatus.color.opacity(0.7)]
        }
        return [.blue, .purple]
    }
}

// MARK: - Quick Stats Section
private struct QuickStatsSection: View {
    let patient: Patient
    let appointments: [Appointment]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Stats")
                .font(.headline)
            
            HStack(spacing: 12) {
                QuickStatCard(
                    icon: "calendar",
                    label: "Age",
                    value: patient.age > 0 ? "\(patient.age) yrs" : "N/A",
                    color: .blue
                )
                
                QuickStatCard(
                    icon: "calendar.badge.clock",
                    label: "Appointments",
                    value: "\(appointments.count)",
                    color: .purple
                )
                
                if let admissionDate = patient.admissionDate,
                   patient.admissionStatus == "admitted" {
                    let days = Calendar.current.dateComponents([.day], from: admissionDate, to: Date()).day ?? 0
                    QuickStatCard(
                        icon: "bed.double",
                        label: "Days Admitted",
                        value: "\(days)",
                        color: .orange
                    )
                }
            }
        }
    }
}

// MARK: - Quick Stat Card
private struct QuickStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

// MARK: - Medical Information Section
// MARK: - Medical History Row


// MARK: - Contact Information Section
private struct ContactInformationSection: View {
    let patient: Patient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Contact Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                InfoRow(
                    icon: "phone.fill",
                    label: "Phone",
                    value: patient.phoneNumber ?? "N/A",
                    color: .green
                )
                
                if let email = patient.email {
                    InfoRow(
                        icon: "envelope.fill",
                        label: "Email",
                        value: email,
                        color: .blue
                    )
                }
                
                if let address = patient.address {
                    InfoRow(
                        icon: "location.fill",
                        label: "Address",
                        value: address,
                        color: .orange
                    )
                }
                
                if let emergencyContact = patient.emergencyContact {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Emergency Contact", systemImage: "person.fill.badge.plus")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.red)
                        
                        Text(emergencyContact)
                            .font(.subheadline)
                        
                        if let relation = patient.emergencyContactRelation {
                            Text(relation)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.red.opacity(0.1))
                    )
                }
            }
        }
    }
}

// MARK: - Admission Information Section
private struct AdmissionInformationSection: View {
    let patient: Patient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Admission Information")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let admissionDate = patient.admissionDate {
                    InfoRow(
                        icon: "calendar.badge.plus",
                        label: "Admission Date",
                        value: admissionDate.formatted(date: .long, time: .omitted),
                        color: .blue
                    )
                }
                
                if let dischargeDate = patient.dischargeDate {
                    InfoRow(
                        icon: "calendar.badge.checkmark",
                        label: "Discharge Date",
                        value: dischargeDate.formatted(date: .long, time: .omitted),
                        color: .green
                    )
                }
                
                if let doctorId = patient.assignedDoctorId {
                    InfoRow(
                        icon: "stethoscope",
                        label: "Assigned Doctor ID",
                        value: doctorId.uuidString.prefix(8) + "...",
                        color: .purple
                    )
                }
            }
        }
    }
}

// MARK: - Recent Appointments Section
private struct RecentAppointmentsSection: View {
    let appointments: [Appointment]
    let isLoading: Bool
    let patient: Patient
    let staffId: UUID
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Appointments")
                .font(.headline)
            
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if appointments.isEmpty {
                Text("No appointments found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(appointments.prefix(5)) { appointment in
                        NavigationLink {
                            ConsultationView(
                                appointment: appointment,
                                patient: patient,
                                staffId: staffId
                            )
                        } label: {
                            AppointmentRow(appointment: appointment)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Appointment Row
private struct AppointmentRow: View {
    let appointment: Appointment
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(appointment.formattedDate)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(appointment.formattedSlot)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(appointment.appointmentStatus.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.2))
                )
                .foregroundStyle(statusColor)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var statusColor: Color {
        switch appointment.appointmentStatus {
        case .scheduled:
            return .blue
        case .confirmed:
            return .green
        case .inProgress:
            return .orange
        case .completed:
            return .gray
        case .cancelled:
            return .red
        case .noShow:
            return .orange
        case .rescheduled:
            return .purple
        }
    }
}

private struct InfoRow: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

private struct EditPatientView: View {
    let patient: Patient
    let viewModel: PatientSearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName: String
    @State private var phoneNumber: String
    @State private var email: String
    
    init(patient: Patient, viewModel: PatientSearchViewModel) {
        self.patient = patient
        self.viewModel = viewModel
        _fullName = State(initialValue: patient.fullName)
        _phoneNumber = State(initialValue: patient.phoneNumber ?? "")
        _email = State(initialValue: patient.email ?? "")
    }
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Full Name", text: $fullName)
                TextField("Phone Number", text: $phoneNumber)
                TextField("Email", text: $email)
            }
        }
        .navigationTitle("Edit Patient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    let updatedPatient = Patient(
                        id: patient.id,
                        fullName: fullName,
                        email: email.isEmpty ? nil : email,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                        dateOfBirth: patient.dateOfBirth,
                        gender: patient.gender,
                        createdAt: patient.createdAt,
                        bloodGroup: patient.bloodGroup,
                        allergies: patient.allergies,
                        currentMedications: patient.currentMedications,
                        medicalHistory: patient.medicalHistory,
                        admissionStatus: patient.admissionStatus,
                        admissionDate: patient.admissionDate,
                        dischargeDate: patient.dischargeDate,
                        assignedDoctorId: patient.assignedDoctorId,
                        emergencyContact: patient.emergencyContact,
                        emergencyContactRelation: patient.emergencyContactRelation,
                        medicalRecordNumber: patient.medicalRecordNumber,
                        address: patient.address
                    )
                    
                    Task {
                        await viewModel.updatePatient(updatedPatient)
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
            }
        }
    }
}
