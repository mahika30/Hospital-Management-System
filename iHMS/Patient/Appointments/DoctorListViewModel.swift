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
    @Published var selectedDepartment: String? = nil
    @Published var isLoading = false

    private let staffService = StaffService()
    
    var departments: [String] {
        let allDepts = doctors.compactMap { $0.departmentId }.filter { !$0.isEmpty }
        return Array(Set(allDepts)).sorted()
    }

    var filteredDoctors: [Staff] {
        var result = doctors
        
        // Filter by department
        if let dept = selectedDepartment {
            result = result.filter { $0.departmentId == dept }
        }
        
        // Filter by search
        if !searchText.isEmpty {
            result = result.filter {
                $0.fullName.lowercased().contains(searchText.lowercased()) ||
                $0.designation?.lowercased().contains(searchText.lowercased()) == true
            }
        }
        
        return result
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
