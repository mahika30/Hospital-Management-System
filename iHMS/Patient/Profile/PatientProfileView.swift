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

    var body: some View {
        ZStack {

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {

                    profileCard

                    personalInfoCard

                    medicalInfoCard

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
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(isEditing ? "Save" : "Edit") {
                    if isEditing {
                        Task { await saveProfile() }
                    } else {
                        isEditing = true
                    }
                }
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
                .foregroundColor(.white.opacity(0.9))

            Text(fullName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            HStack(spacing: 12) {
                pill("Age", "\(viewModel.age)")
                pill("Gender", gender)
                pill("Blood", bloodGroup)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(26)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.25, blue: 0.45),
                    Color.black
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(30)
    }

    private var personalInfoCard: some View {
        VStack(alignment: .leading, spacing: 18) {

            sectionTitle("Personal Details")

            infoRow(title: "Full Name", text: $fullName)
            infoRow(title: "Phone Number", text: $phoneNumber)
            infoRow(title: "Gender", text: $gender)
            infoRow(title: "Blood Group", text: $bloodGroup)

            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(20)
    }

    private var medicalInfoCard: some View {
        VStack(alignment: .leading, spacing: 14) {

            sectionTitle("Medical Information")

            readOnlyChip("Blood Test Report")
            readOnlyChip("MRI Scan")
            readOnlyChip("Paracetamol – 5 days")
        }
        .padding()
        .background(Color.black)
        .cornerRadius(20)
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
            .background(Color.white.opacity(0.08))
            .cornerRadius(18)
        }
    }

    // MARK: - COMPONENTS

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .foregroundColor(.white)
    }

    private func pill(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }

    private func infoRow(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            if isEditing {
                TextField(title, text: text)
                    .padding()
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
                    .foregroundColor(.white)
            } else {
                Text(text.wrappedValue.isEmpty ? "-" : text.wrappedValue)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(12)
            }
        }
    }

    private func readOnlyChip(_ text: String) -> some View {
        Text(text)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.08))
            .cornerRadius(12)
    }

    // MARK: - LOGIC

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

            isEditing = false
        } catch {
            errorMessage = error.localizedDescription
        }

        isSaving = false
    }
}
