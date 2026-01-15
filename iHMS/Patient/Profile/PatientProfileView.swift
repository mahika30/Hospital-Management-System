import SwiftUI

struct PatientProfileView: View {
    @ObservedObject var viewModel: PatientViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var gender = ""
    @State private var bloodGroup = ""
    
    @State private var showingMedicalHistory = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {

                    profileCard

                    personalInfoCard
                    


                    logoutButton
                }
                .padding()
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") { dismiss() }
                    .foregroundColor(.accentColor)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task { await saveProfile() }
                    } else {
                        isEditing = true
                    }
                }
                .foregroundColor(.accentColor)
                .disabled(isSaving)
            }
        }
        .onAppear {
            loadInitialValues()
        }
    }

    private var profileCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 70))
                .foregroundColor(.accentColor)

            Text(fullName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            HStack(spacing: 12) {
                pill("Age", "\(viewModel.age)")
                pill("Gender", gender)
                pill("Blood", bloodGroup)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }

    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 18) {

            sectionTitle("Personal Details")

            infoRow(title: "Full Name", text: $fullName)
            infoRow(title: "Phone Number", text: $phoneNumber)
            infoRow(title: "Gender", text: $gender)
            infoRow(title: "Blood Group", text: $bloodGroup)
            
            Divider()
            
            NavigationLink {
                if let patient = viewModel.patient {
                    UpdateMedicalHistoryView(patient: patient) { updatedPatient in
                        Task {
                            do {
                                try await PatientService().updatePatient(
                                    id: updatedPatient.id,
                                    fullName: updatedPatient.fullName,
                                    dateOfBirth: updatedPatient.dateOfBirth,
                                    gender: updatedPatient.gender,
                                    phoneNumber: updatedPatient.phoneNumber,
                                    email: updatedPatient.email,
                                    bloodGroup: updatedPatient.bloodGroup,
                                    allergies: updatedPatient.allergies,
                                    currentMedications: updatedPatient.currentMedications,
                                    medicalHistory: updatedPatient.medicalHistory,
                                    admissionStatus: updatedPatient.admissionStatus,
                                    admissionDate: updatedPatient.admissionDate?.ISO8601Format(),
                                    dischargeDate: updatedPatient.dischargeDate?.ISO8601Format(),
                                    assignedDoctorId: updatedPatient.assignedDoctorId?.uuidString,
                                    emergencyContact: updatedPatient.emergencyContact,
                                    emergencyContactRelation: updatedPatient.emergencyContactRelation,
                                    medicalRecordNumber: updatedPatient.medicalRecordNumber,
                                    address: updatedPatient.address
                                )
                                await viewModel.loadDashboardData(authVM: authVM)
                            } catch {
                                print("Failed to save patient history: \(error)")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Medical History")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("Chronic diseases, allergies, medications")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.gray)
                }
                .padding(.vertical, 4)
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 0.5)
        )
    }


    


    private var logoutButton: some View {
        Button {
            Task { await authVM.signOut() }
        } label: {
            HStack {
                Image(systemName: "power")
                Text("Log Out")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
    }

    // MARK: - COMPONENTS

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.primary)
    }

    private func pill(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.tertiarySystemGroupedBackground))
        )
    }

    private func infoRow(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            if isEditing {
                TextField(title, text: text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
            } else {
                Text(text.wrappedValue.isEmpty ? "-" : text.wrappedValue)
                    .foregroundColor(.primary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemGroupedBackground))
                    )
            }
        }
    }

    private func loadInitialValues() {
        fullName = viewModel.patient?.fullName ?? ""
        phoneNumber = viewModel.patient?.phoneNumber ?? ""
        gender = viewModel.patient?.gender ?? ""
        bloodGroup = viewModel.bloodGroup
    }

    private func saveProfile() async {
        guard let patient = viewModel.patient else { return }

        isSaving = true
        errorMessage = nil

        do {
            try await PatientService().updatePatient(
                id: patient.id,
                fullName: fullName,
                dateOfBirth: patient.dateOfBirth,
                gender: gender.isEmpty ? nil : gender,
                phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                email: patient.email,
                bloodGroup: bloodGroup.isEmpty ? nil : bloodGroup,
                allergies: patient.allergies,
                currentMedications: patient.currentMedications,
                medicalHistory: patient.medicalHistory,
                admissionStatus: patient.admissionStatus,
                admissionDate: patient.admissionDate?.ISO8601Format(),
                dischargeDate: patient.dischargeDate?.ISO8601Format(),
                assignedDoctorId: patient.assignedDoctorId?.uuidString,
                emergencyContact: patient.emergencyContact,
                emergencyContactRelation: patient.emergencyContactRelation,
                medicalRecordNumber: patient.medicalRecordNumber,
                address: patient.address
            )
            
            // Reload patient data after save
            await viewModel.loadDashboardData(authVM: authVM)
            loadInitialValues()

            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
