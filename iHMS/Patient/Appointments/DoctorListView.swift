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
    @State private var showSearchBar = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    // Department Filters
                    if !viewModel.departments.isEmpty {
                        departmentFilters
                    }
                    
                    // Doctors Grid
                    doctorsGrid
                }
                .padding()
                .padding(.bottom, showSearchBar ? 80 : 20)
            }
            
            // Floating Search Bar
            if showSearchBar {
                floatingSearchBar
            }
        }
        .navigationTitle("Select Doctor")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        showSearchBar.toggle()
                        if !showSearchBar {
                            viewModel.searchText = ""
                        }
                    }
                } label: {
                    Image(systemName: showSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                        .font(.title3)
                        .foregroundColor(.blue)
                }
            }
        }
        .task {
            await viewModel.loadDoctors()
        }
    }
    
    // MARK: - Department Filters
    private var departmentFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // All button
                FilterChip(
                    title: "All",
                    isSelected: viewModel.selectedDepartment == nil
                ) {
                    withAnimation {
                        viewModel.selectedDepartment = nil
                    }
                }
                
                // Department buttons
                ForEach(viewModel.departments, id: \.self) { dept in
                    FilterChip(
                        title: departmentName(dept),
                        isSelected: viewModel.selectedDepartment == dept
                    ) {
                        withAnimation {
                            viewModel.selectedDepartment = dept == viewModel.selectedDepartment ? nil : dept
                        }
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Doctors Grid
    private var doctorsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(viewModel.filteredDoctors) { doctor in
                NavigationLink {
                    BookAppointmentView(selectedDoctor: doctor)
                } label: {
                    DoctorCard(doctor: doctor)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Floating Search Bar
    private var floatingSearchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search doctors...", text: $viewModel.searchText)
                .textFieldStyle(.plain)
            
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
        .padding(.bottom, 20)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
    
    private func departmentName(_ id: String) -> String {
        switch id {
        case "general": return "General"
        case "cardiology": return "Cardiology"
        case "neurology": return "Neurology"
        case "orthopedics": return "Orthopedics"
        case "pediatrics": return "Pediatrics"
        case "gynecology": return "Gynecology"
        case "ent": return "ENT"
        case "dermatology": return "Dermatology"
        case "urology": return "Urology"
        default: return id.capitalized
        }
    }
}

// MARK: - Doctor Card
struct DoctorCard: View {
    let doctor: Staff
    
    var body: some View {
        VStack(spacing: 12) {
            // Avatar
            Circle()
                .fill(doctor.avatarColor)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(doctor.initials)
                        .foregroundColor(.white)
                        .font(.title3)
                        .fontWeight(.semibold)
                )
            
            // Info
            VStack(spacing: 4) {
                Text(doctor.fullName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let designation = doctor.designation {
                    Text(designation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                if let dept = doctor.departmentId {
                    HStack(spacing: 4) {
                        Image(systemName: "stethoscope")
                            .font(.caption2)
                        Text(departmentShortName(dept))
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray5), lineWidth: 1)
        )
    }
    
    private func departmentShortName(_ id: String) -> String {
        switch id {
        case "general": return "General"
        case "cardiology": return "Cardio"
        case "neurology": return "Neuro"
        case "orthopedics": return "Ortho"
        case "pediatrics": return "Pedia"
        case "gynecology": return "Gynec"
        case "ent": return "ENT"
        case "dermatology": return "Derm"
        case "urology": return "Uro"
        default: return id.capitalized
        }
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
        }
    }
}
