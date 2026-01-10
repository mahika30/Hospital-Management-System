//
//  PatientProfileLoaderView.swift
//  iHMS
//
//  Created by Hargun Singh on 10/01/26.
//

//
//  PatientDetailLoaderView.swift
//  iHMS
//

import SwiftUI

struct PatientDetailLoaderView: View {

    let patientId: UUID

    @StateObject private var vm = PatientProfileViewModel()
    let searchVM = PatientSearchViewModel()


    var body: some View {
        ZStack {
            if vm.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Loading patient...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            else if let patient = vm.patient {
                PatientDetailView(
                    patient: patient,
                    viewModel: searchVM
                )
            }
            else {
                Text("Patient not found")
                    .foregroundColor(.red)
            }
        }
        .task {
            await vm.fetchPatient(by: patientId.uuidString)
        }
    }
}


