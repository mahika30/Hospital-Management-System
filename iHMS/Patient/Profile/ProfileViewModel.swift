//
//  ProfileViewModel.swift
//  iHMS
//
//  Created on 05/01/26.
//

import Foundation
import Combine
import SwiftUI
import Supabase
import PostgREST

@MainActor
final class PatientViewModel: ObservableObject {

    @Published var patient: Patient?
    @Published var appointments: [Appointment] = []
    @Published var upcomingFollowUps: [Prescription] = []
    @Published var aiSuggestions: [AISlotSuggestion] = []
    @Published var suggestionsVisible: Bool = true
    @Published var cachedStaff: [Staff] = []

    private let patientService = PatientService()
    private let appointmentService = AppointmentService()
    private let supabase = SupabaseManager.shared.client
    
    struct AISlotSuggestion: Identifiable {
        let id = UUID()
        let staffId: UUID
        let staffName: String
        let date: String
        let timeRange: String
        let reason: String
    }
    func loadDashboardData(authVM: AuthViewModel) async {
        guard let userId = await authVM.currentUserId() else { return }

        do {
            async let patientTask = patientService.fetchPatient(id: userId)
            async let appointmentsTask = appointmentService.fetchAppointments(for: userId)

            self.patient = try await patientTask
            self.appointments = try await appointmentsTask
            
            // Load upcoming follow-ups
            await loadUpcomingFollowUps(patientId: userId)
            
            // Load AI suggestions
            await loadAISuggestions(patientId: userId)
        } catch {
            print("Failed to load dashboard data:", error)
        }
    }
    
    private func loadUpcomingFollowUps(patientId: UUID) async {
        do {
            let today = Date()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let todayString = formatter.string(from: today)
            
            let prescriptions: [Prescription] = try await supabase
                .from("prescriptions")
                .select("""
                    *,
                    staff:staff_id(id, full_name, email)
                """)
                .eq("patient_id", value: patientId.uuidString)
                .gte("follow_up_date", value: todayString)
                .order("follow_up_date", ascending: true)
                .limit(5)
                .execute()
                .value
            
            upcomingFollowUps = prescriptions.filter { $0.followUpDate != nil }
            print("✅ Loaded \(upcomingFollowUps.count) upcoming follow-ups")
        } catch {
            print("❌ Error loading follow-ups: \(error)")
        }
    }
    
    @MainActor
    func updateMedicalHistory(
        medicalHistory: String?,
        allergies: [String]?,
        currentMedications: [String]?
    ) async throws {

        guard let patient else {
            throw NSError(domain: "PatientMissing", code: 0)
        }

        try await patientService.updateMedicalHistory(
            patientId: patient.id,
            medicalHistory: medicalHistory,
            allergies: allergies,
            currentMedications: currentMedications
        )
        self.patient = try await patientService.fetchPatient(id: patient.id)
    }

    
    private func loadAISuggestions(patientId: UUID) async {
        do {
            print("🤖 Loading AI suggestions for dashboard...")
            
            // Fetch analytics data
            let (appointments, slots, staff) = try await AnalyticsService.shared.fetchAnalyticsData()
            
            // Cache staff as Staff objects for navigation
            cachedStaff = staff.compactMap { analyticsStaff in
                Staff(
                    id: analyticsStaff.id,
                    fullName: analyticsStaff.fullName,
                    email: "", // Not available in analytics
                    departmentId: nil,
                    designation: analyticsStaff.specialization,
                    phone: nil,
                    createdAt: nil as String?
                )
            }
            
            // Get AI suggestions (top 3 for dashboard)
            let suggestions = AnalyticsService.shared.suggestAppointmentSlots(
                for: patientId,
                history: appointments,
                slots: slots,
                staff: staff,
                limit: 3
            )
            
            print("💡 Dashboard AI suggestions: \(suggestions.count) results")
            
            // Parse suggestions
            var parsedSuggestions: [AISlotSuggestion] = []
            
            for suggestion in suggestions {
                let components = suggestion.components(separatedBy: " @ ")
                guard components.count == 2 else { continue }
                
                let date = components[0].trimmingCharacters(in: .whitespaces)
                let rest = components[1].components(separatedBy: " with ")
                guard rest.count == 2 else { continue }
                
                let timeRange = rest[0].trimmingCharacters(in: .whitespaces)
                var doctorInfo = rest[1].trimmingCharacters(in: .whitespaces)
                
                var reason = "Recommended for you"
                if doctorInfo.contains("(⭐ Your Doctor)") {
                    doctorInfo = doctorInfo.replacingOccurrences(of: " (⭐ Your Doctor)", with: "")
                    reason = "Your preferred doctor"
                }
                
                if let matchingStaff = staff.first(where: { $0.fullName == doctorInfo }) {
                    parsedSuggestions.append(AISlotSuggestion(
                        staffId: matchingStaff.id,
                        staffName: doctorInfo,
                        date: date,
                        timeRange: timeRange,
                        reason: reason
                    ))
                }
            }
            
            aiSuggestions = parsedSuggestions
            print("✅ Loaded \(aiSuggestions.count) AI suggestions for dashboard")
        } catch {
            print("❌ Error loading AI suggestions: \(error)")
        }
    }
    
    func dismissSuggestions() {
        suggestionsVisible = false
    }
    
    func findStaff(byId staffId: UUID) -> Staff? {
        return cachedStaff.first { $0.id == staffId }
    }


    var name: String {
        patient?.fullName ?? "Patient"
    }

    var gender: String {
        patient?.gender ?? "-"
    }

    var bloodGroup: String {
        patient?.bloodGroup ?? "-"
    }

    var age: Int {
        guard let dobString = patient?.dateOfBirth else { return 0 }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")

        let formats = [
            "yyyy-MM-dd",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd HH:mm:ss"
        ]

        for format in formats {
            formatter.dateFormat = format
            if let dob = formatter.date(from: dobString) {
                return Calendar.current
                    .dateComponents([.year], from: dob, to: Date())
                    .year ?? 0
            }
        }
        return 0
    }

    var qrCodeData: String {
        patient?.id.uuidString ?? "N/A"
    }
    
    
}
