import SwiftUI
import Supabase

@MainActor
@Observable
final class PatientSearchViewModel {
    var patients: [Patient] = []
    var filteredPatients: [Patient] = []
    var appointments: [Appointment] = []
    var isLoading = false
    var errorMessage: String?
    var searchQuery = "" {
        didSet {
            filterPatients()
        }
    }
    var selectedTimeline: TimelineFilter = .all {
        didSet {
            filterPatients()
        }
    }
    var selectedSortOption: SortOption = .nameAsc {
        didSet {
            filterPatients()
        }
    }
    
    enum TimelineFilter: String, CaseIterable {
        case all = "All"
        case today = "Today"
        case thisWeek = "This Week"
        case thisMonth = "This Month"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .today: return "calendar"
            case .thisWeek: return "calendar.badge.clock"
            case .thisMonth: return "calendar.badge.plus"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case nameAsc = "Name (A-Z)"
        case nameDesc = "Name (Z-A)"
        case dateAsc = "Date (Oldest)"
        case dateDesc = "Date (Newest)"
        
        var icon: String {
            switch self {
            case .nameAsc, .nameDesc: return "textformat"
            case .dateAsc, .dateDesc: return "calendar"
            }
        }
    }
    
    // MARK: - Computed Properties
    var totalCount: Int {
        patients.count
    }
    
    var hasActiveFilters: Bool {
        !searchQuery.isEmpty || selectedTimeline != .all
    }
    
    // MARK: - Initialization
    init() {
        Task {
            await loadPatients()
        }
    }
    
    // MARK: - Public Methods
    func loadPatients() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Get current staff ID
            guard let staffId = try? await SupabaseManager.shared.client.auth.session.user.id else {
                errorMessage = "Unable to get staff ID"
                isLoading = false
                return
            }
            
            print("🔍 Loading patients from appointments for doctor: \(staffId)")
            
            // Fetch appointments for this doctor
            let appointments: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select()
                .eq("staff_id", value: staffId.uuidString)
                .execute()
                .value
            
            print("✅ Found \(appointments.count) appointments")
            
            // Store appointments for filtering
            self.appointments = appointments
            
            // Get unique patient IDs from appointments
            let patientIds = Array(Set(appointments.map { $0.patientId }))
            
            print("🔍 Fetching details for \(patientIds.count) unique patients")
            
            // Fetch patient details for those patient IDs
            if patientIds.isEmpty {
                patients = []
                filterPatients()
                isLoading = false
                return
            }
            
            let response: [Patient] = try await SupabaseManager.shared.client
                .from("patients")
                .select()
                .in("id", values: patientIds.map { $0.uuidString })
                .order("full_name")
                .execute()
                .value
            
            print("✅ Loaded \(response.count) patient records")
            patients = response
            filterPatients()
        } catch {
            errorMessage = "Failed to load patients: \(error.localizedDescription)"
            print("❌ Error loading patients: \(error)")
        }
        
        isLoading = false
    }
    
    func refreshPatients() async {
        await loadPatients()
    }
    
    func filterPatients() {
        var result = patients
        
        // Apply search query
        if !searchQuery.isEmpty {
            result = result.filter { patient in
                patient.fullSearchText.localizedCaseInsensitiveContains(searchQuery)
            }
        }
        
        // Apply timeline filter
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeline {
        case .all:
            break
        case .today:
            result = result.filter { patient in
                appointments.contains { appointment in
                    appointment.patientId == patient.id &&
                    calendar.isDateInToday(parseAppointmentDate(appointment.appointmentDate))
                }
            }
        case .thisWeek:
            result = result.filter { patient in
                appointments.contains { appointment in
                    appointment.patientId == patient.id &&
                    calendar.isDate(parseAppointmentDate(appointment.appointmentDate), equalTo: now, toGranularity: .weekOfYear)
                }
            }
        case .thisMonth:
            result = result.filter { patient in
                appointments.contains { appointment in
                    appointment.patientId == patient.id &&
                    calendar.isDate(parseAppointmentDate(appointment.appointmentDate), equalTo: now, toGranularity: .month)
                }
            }
        }
        
        // Apply sorting
        result.sort { patient1, patient2 in
            switch selectedSortOption {
            case .nameAsc:
                return patient1.fullName < patient2.fullName
            case .nameDesc:
                return patient1.fullName > patient2.fullName
            case .dateAsc:
                let date1 = patient1.createdAt ?? Date.distantPast
                let date2 = patient2.createdAt ?? Date.distantPast
                return date1 < date2
            case .dateDesc:
                let date1 = patient1.createdAt ?? Date.distantPast
                let date2 = patient2.createdAt ?? Date.distantPast
                return date1 > date2
            }
        }
        
        filteredPatients = result
    }
    
    func clearFilters() {
        searchQuery = ""
        selectedTimeline = .all
        selectedSortOption = .nameAsc
    }
    
    func deletePatient(_ patient: Patient) async {
        do {
            try await SupabaseManager.shared.client
                .from("patients")
                .delete()
                .eq("id", value: patient.id.uuidString)
                .execute()
            
            // Remove from local array
            patients.removeAll { $0.id == patient.id }
            filterPatients()
        } catch {
            errorMessage = "Failed to delete patient: \(error.localizedDescription)"
            print("❌ Error deleting patient: \(error)")
        }
    }
    
    func updatePatient(_ patient: Patient) async {
        do {
            let dto = PatientUpdateDTO(
                fullName: patient.fullName,
                dateOfBirth: patient.dateOfBirth,
                gender: patient.gender,
                phoneNumber: patient.phoneNumber,
                email: patient.email,
                bloodGroup: patient.bloodGroup,
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
            
            try await SupabaseManager.shared.client
                .from("patients")
                .update(dto)
                .eq("id", value: patient.id.uuidString)
                .execute()
            
            // Update local array
            if let index = patients.firstIndex(where: { $0.id == patient.id }) {
                patients[index] = patient
            }
            filterPatients()
        } catch {
            errorMessage = "Failed to update patient: \(error.localizedDescription)"
            print("❌ Error updating patient: \(error)")
        }
    }
    
    func addPatient(_ patient: Patient) async {
        do {
            struct PatientInsertDTO: Encodable {
                let id: String
                let fullName: String
                let dateOfBirth: String?
                let gender: String?
                let phoneNumber: String?
                let email: String?
                let allergies: [String]?
                let currentMedications: [String]?
                let medicalHistory: String?
                let admissionStatus: String?
                let admissionDate: String?
                let assignedDoctorId: String?
                let emergencyContact: String?
                let emergencyContactRelation: String?
                let medicalRecordNumber: String?
                let address: String?
                
                enum CodingKeys: String, CodingKey {
                    case id
                    case fullName = "full_name"
                    case dateOfBirth = "date_of_birth"
                    case gender
                    case phoneNumber = "phone_number"
                    case email
                    case allergies
                    case currentMedications = "current_medications"
                    case medicalHistory = "medical_history"
                    case admissionStatus = "admission_status"
                    case admissionDate = "admission_date"
                    case assignedDoctorId = "assigned_doctor_id"
                    case emergencyContact = "emergency_contact"
                    case emergencyContactRelation = "emergency_contact_relation"
                    case medicalRecordNumber = "medical_record_number"
                    case address
                }
            }
            
            let dto = PatientInsertDTO(
                id: patient.id.uuidString,
                fullName: patient.fullName,
                dateOfBirth: patient.dateOfBirth,
                gender: patient.gender,
                phoneNumber: patient.phoneNumber,
                email: patient.email,
                allergies: patient.allergies,
                currentMedications: patient.currentMedications,
                medicalHistory: patient.medicalHistory,
                admissionStatus: patient.admissionStatus,
                admissionDate: patient.admissionDate?.ISO8601Format(),
                assignedDoctorId: patient.assignedDoctorId?.uuidString,
                emergencyContact: patient.emergencyContact,
                emergencyContactRelation: patient.emergencyContactRelation,
                medicalRecordNumber: patient.medicalRecordNumber,
                address: patient.address
            )
            
            try await SupabaseManager.shared.client
                .from("patients")
                .insert(dto)
                .execute()
            
            // Add to local array
            patients.append(patient)
            filterPatients()
        } catch {
            errorMessage = "Failed to add patient: \(error.localizedDescription)"
            print("❌ Error adding patient: \(error)")
        }
    }
    
    func getPatientAppointments(_ patientId: UUID) async -> [Appointment] {
        do {
            let response: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select("""
                    *,
                    time_slots(
                        start_time,
                        end_time,
                        slot_date
                    ),
                    staff(
                        full_name
                    )
                """)
                .eq("patient_id", value: patientId.uuidString)
                .order("appointment_date", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            print("❌ Error loading patient appointments: \(error)")
            return []
        }
    }
    
    // MARK: - Helper Methods
    private func parseAppointmentDate(_ dateString: String) -> Date {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: dateString) ?? Date()
    }
}
