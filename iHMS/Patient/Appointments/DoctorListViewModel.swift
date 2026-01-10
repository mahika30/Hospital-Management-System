//
//  DoctorListViewModel.swift
//  iHMS
//
//  Created by Navdeep Singh on 08/01/26.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class DoctorListViewModel: ObservableObject {

    @Published var doctors: [Staff] = []
    @Published var searchText = ""
    @Published var isLoading = false

    private let staffService = StaffService()

    var filteredDoctors: [Staff] {
        guard !searchText.isEmpty else { return doctors }
        return doctors.filter {
            $0.fullName.lowercased().contains(searchText.lowercased())
        }
    }

    func loadDoctors() async {
        isLoading = true
        do {
            doctors = try await staffService.fetchStaff()
        } catch {
            print("Failed to load doctors")
        }
        isLoading = false
    }
}
