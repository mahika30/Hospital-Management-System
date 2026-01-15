import SwiftUI

struct UpdateMedicalHistoryView: View {
    let patient: Patient
    let onSave: ((Patient) async throws -> Void)?

    @Environment(\.dismiss) private var dismiss

    @State private var medicalHistory: String = ""
    @State private var allergies: String = ""
    @State private var currentMedications: String = ""

    @State private var isEditing = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    init(patient: Patient, onSave: ((Patient) async throws -> Void)? = nil) {
        self.patient = patient
        self.onSave = onSave
        _medicalHistory = State(initialValue: patient.medicalHistory ?? "")
        _allergies = State(initialValue: patient.allergies?.joined(separator: ", ") ?? "")
        _currentMedications = State(initialValue: patient.currentMedications?.joined(separator: ", ") ?? "")
    }

    var body: some View {
        List {

            Section(header: Text("Past Medical Situations & Chronic Diseases")) {
                if isEditing {
                    TextEditor(text: $medicalHistory)
                        .frame(minHeight: 120)
                } else {
                    Text(medicalHistory.isEmpty ? "No history recorded" : medicalHistory)
                        .foregroundStyle(medicalHistory.isEmpty ? .secondary : .primary)
                }
            }

            Section(header: Text("Allergies")) {
                if isEditing {
                    TextField("e.g., Peanuts, Penicillin", text: $allergies)
                } else {
                    Text(allergies.isEmpty ? "No allergies recorded" : allergies)
                        .foregroundStyle(allergies.isEmpty ? .secondary : .primary)
                }
            }

            Section(header: Text("Other / Current Medications")) {
                if isEditing {
                    TextField("e.g., Aspirin, Metformin", text: $currentMedications)
                } else {
                    Text(currentMedications.isEmpty ? "No medications recorded" : currentMedications)
                        .foregroundStyle(currentMedications.isEmpty ? .secondary : .primary)
                }
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                }
            }
        }
        .navigationTitle("Medical History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let onSave {
                    if isEditing {
                        Button("Save") {
                            Task {
                                await saveMedicalHistory(saveAction: onSave)
                            }
                        }
                        .disabled(isSaving)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
        }
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.15).ignoresSafeArea()
                    ProgressView()
                }
            }
        }
    }

    @MainActor
    private func saveMedicalHistory(
        saveAction: (Patient) async throws -> Void
    ) async {
        isSaving = true
        errorMessage = nil

        let allergiesArray = allergies
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let medicationsArray = currentMedications
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var updatedPatient = patient
        updatedPatient.medicalHistory = medicalHistory
        updatedPatient.allergies = allergiesArray
        updatedPatient.currentMedications = medicationsArray

        do {
            try await saveAction(updatedPatient)
            isEditing = false
            isSaving = false
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
            isSaving = false
        }
    }

}
