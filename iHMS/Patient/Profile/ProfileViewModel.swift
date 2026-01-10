//
//  ProfileViewModel.swift
//  iHMS
//
//  Created on 05/01/26.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class PatientViewModel: ObservableObject {

    @Published var patient: Patient?
    @Published var appointments: [Appointment] = []

    private let patientService = PatientService()
    private let appointmentService = AppointmentService()
    func loadDashboardData(authVM: AuthViewModel) async {
        guard let userId = await authVM.currentUserId() else { return }

        do {
            async let patientTask = patientService.fetchPatient(id: userId)
            async let appointmentsTask = appointmentService.fetchAppointments(for: userId)

            self.patient = try await patientTask
            self.appointments = try await appointmentsTask
        } catch {
            print("Failed to load dashboard data:", error)
        }
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
