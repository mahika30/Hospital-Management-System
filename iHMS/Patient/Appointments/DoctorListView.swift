//
//  DoctorListView.swift
//  iHMS
//
//  Created by Navdeep Singh on 08/01/26.
//

import SwiftUI
import SwiftUI

extension Staff {

    var initials: String {
        let parts = fullName.split(separator: " ")
        let first = parts.first?.first.map(String.init) ?? ""
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return first + second
    }

    var avatarColor: Color {
        let colors: [Color] = [
            .blue, .green, .purple,
            .orange, .pink, .teal,
            .indigo, .red
        ]
        return colors[abs(id.hashValue) % colors.count]
    }
}

struct DoctorListView: View {

    @StateObject private var viewModel = DoctorListViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.filteredDoctors) { doctor in

                NavigationLink {
                    BookAppointmentView(selectedDoctor: doctor)
                } label: {

                    HStack(spacing: 16) {

                        // Avatar circle
                        Circle()
                            .fill(doctor.avatarColor)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Text(doctor.initials)
                                    .foregroundColor(.white)
                                    .font(.headline)
                            )

                        VStack(alignment: .leading, spacing: 4) {
                            Text(doctor.fullName)
                                .font(.headline)

                            if let designation = doctor.designation {
                                Text(designation)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }

                        }
                    }
                    .padding(.vertical, 6)
                }
            }
            .navigationTitle("Select Doctor")
            .searchable(text: $viewModel.searchText)
            .task {
                await viewModel.loadDoctors()
            }
        }
    }
}
