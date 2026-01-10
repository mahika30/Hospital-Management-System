//
//  PatientProfileViewModel.swift
//  iHMS
//
//  Created by Hargun Singh on 10/01/26.
//


import Supabase
import SwiftUI
import Combine

@MainActor
final class PatientProfileViewModel: ObservableObject {

    @Published var patient: Patient?
    @Published var isLoading = false

    func fetchPatient(by id: String) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let response: Patient = try await SupabaseManager.shared.client
                .from("patients")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value

            self.patient = response
        } catch {
            print("Fetch patient error:", error)
        }
    }
}
