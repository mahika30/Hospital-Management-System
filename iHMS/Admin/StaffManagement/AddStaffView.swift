import SwiftUI
import Supabase

struct AddStaffView: View {

    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var email = ""
    @State private var selectedDepartment: Department?
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false

    private let supabase = SupabaseManager.shared.client
    private let staffService = StaffService()

    private let departments: [Department] = [
        Department(id: "general", name: "General Medicine"),
        Department(id: "cardiology", name: "Cardiology"),
        Department(id: "neurology", name: "Neurology"),
        Department(id: "neurosurgery", name: "Neurosurgery"),
        Department(id: "orthopedics", name: "Orthopedics"),
        Department(id: "physiotherapy", name: "Physiotherapy"),
        Department(id: "sports_medicine", name: "Sports Medicine"),
        Department(id: "pediatrics", name: "Pediatrics"),
        Department(id: "neonatology", name: "Neonatology"),
        Department(id: "gynecology", name: "Gynecology"),
        Department(id: "obstetrics", name: "Obstetrics"),
        Department(id: "ent", name: "ENT (Ear, Nose & Throat)"),
        Department(id: "ophthalmology", name: "Ophthalmology"),
        Department(id: "psychiatry", name: "Psychiatry"),
        Department(id: "psychology", name: "Psychology"),
        Department(id: "dermatology", name: "Dermatology"),
        Department(id: "endocrinology", name: "Endocrinology"),
        Department(id: "radiology", name: "Radiology"),
        Department(id: "pathology", name: "Pathology"),
        Department(id: "laboratory", name: "Laboratory Medicine"),
        Department(id: "gastroenterology", name: "Gastroenterology"),
        Department(id: "pulmonology", name: "Pulmonology"),
        Department(id: "nephrology", name: "Nephrology"),
        Department(id: "urology", name: "Urology"),
        Department(id: "general_surgery", name: "General Surgery"),
        Department(id: "cardiac_surgery", name: "Cardiac Surgery"),
        Department(id: "plastic_surgery", name: "Plastic Surgery"),
        Department(id: "emergency", name: "Emergency Medicine"),
        Department(id: "critical_care", name: "Critical Care / ICU")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(spacing: 8) {
                    Image(systemName: "stethoscope.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)

                    Text("Invite a Doctor")
                        .font(.title2)
                        .bold()

                    Text("""
                    An invitation email will be sent to the doctor.
                    They must set a password before accessing the system.
                    """)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                }
                .padding()
                Form {

                    Section("Doctor Details") {
                        TextField("Full Name", text: $fullName)

                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }

                    Section("Department") {
                        Picker("Select Department", selection: $selectedDepartment) {
                            Text("Select").tag(Optional<Department>.none)

                            ForEach(departments) { department in
                                Text(department.name)
                                    .tag(Optional(department))
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                    
                    if showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Doctor added successfully! Creating time slots...")
                                .foregroundColor(.green)
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                SwipeToInviteButton(
                    isEnabled: isFormValid,
                    isLoading: isLoading
                ) {
                    await inviteDoctor()
                }
                .padding()
            }
            .navigationTitle("Add Doctor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
        }
    }
    private var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        selectedDepartment != nil
    }
    private func inviteDoctor() async {
        guard let department = selectedDepartment else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signInWithOTP(
                email: email,
                redirectTo: URL(string: "ihms://auth-callback"),
                data: [
                    "full_name": .string(fullName),
//                    "role": .string("staff"),
                    "department_id": .string(department.id)
                ]
            )
            
    
            
            struct StaffInsert: Encodable {
                let full_name: String
                let email: String
                let department_id: String
                let designation: String
                let is_active: Bool
                let role: String
            }
            
            // Create staff record
            let staffInsert = StaffInsert(
                full_name: fullName,
                email: email,
                department_id: department.id,
                designation: "Doctor",
                is_active: true,
                role: "staff"
            )
            
            let insertedStaff: [Staff] = try await supabase
                .from("staff")
                .insert(staffInsert)
                .select()
                .execute()
                .value
            if let newStaff = insertedStaff.first {
                print("✅ Staff created with ID: \(newStaff.id)")
                
                let today = Date()
                let endDate = Calendar.current.date(byAdding: .day, value: 14, to: today) ?? today
                try await staffService.createTimeSlotsForDateRange(
                    staffId: newStaff.id,
                    startDate: today,
                    endDate: endDate,
                    capacity: 5,
                    weekdaysOnly: true
                )
                
                print("✅ Time slots created successfully")
            }
            
            showSuccess = true
            
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            dismiss()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
