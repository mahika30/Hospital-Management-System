import SwiftUI

@MainActor
struct PatientSearchView: View {
    @State private var viewModel = PatientSearchViewModel()
    @State private var selectedPatient: Patient?
    @State private var showingFilterSheet = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 20) {
                    StatsSection(viewModel: viewModel)
                        .padding(.horizontal)
                        .padding(.top, 8)
                    

                    TimelineFilterSection(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Patients List
                    PatientsListSection(
                        viewModel: viewModel,
                        selectedPatient: $selectedPatient
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 80) // Space for bottom search bar
                }
                .padding(.vertical)
            }
            .refreshable {
                await viewModel.refreshPatients()
            }
            
            // Glass-like Floating Search Bar (iOS 26 style)
            HStack(spacing: 12) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                        .font(.system(size: 17, weight: .medium))
                    
                    TextField("Search", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17))
                    
                    if !viewModel.searchQuery.isEmpty {
                        Button {
                            viewModel.searchQuery = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                                .font(.system(size: 16))
                        }
                    } else {
                        Image(systemName: "mic.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 17))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separator).opacity(0.3), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .ignoresSafeArea(edges: .bottom)
            )
        }
        .navigationTitle("Patient Records")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingFilterSheet = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 20))
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.patients.isEmpty {
                LoadingView()
            }
        }
        .sheet(item: $selectedPatient) { patient in
            NavigationStack {
                PatientDetailView(patient: patient, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterSheet(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Stats Section
private struct StatsSection: View {
    let viewModel: PatientSearchViewModel
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Total",
                    value: "\(viewModel.totalCount)",
                    icon: "person.3.fill",
                    color: .blue
                )
            }
        }
    }
}

// MARK: - Stat Card
private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)
            }
            
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(width: 140)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Timeline Filter Section
private struct TimelineFilterSection: View {
    @Bindable var viewModel: PatientSearchViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Timeline")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(PatientSearchViewModel.TimelineFilter.allCases, id: \.self) { filter in
                        TimelineChip(
                            filter: filter,
                            isSelected: viewModel.selectedTimeline == filter
                        ) {
                            viewModel.selectedTimeline = filter
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Timeline Chip
private struct TimelineChip: View {
    let filter: PatientSearchViewModel.TimelineFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(isSelected ? Color.accentColor : Color(.systemGray6))
            )
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Patients List Section
private struct PatientsListSection: View {
    let viewModel: PatientSearchViewModel
    @Binding var selectedPatient: Patient?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Patients")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.filteredPatients.count) results")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            if viewModel.filteredPatients.isEmpty {
                if viewModel.isLoading {
                    SkeletonLoadingView()
                } else {
                    EmptyStateView(
                        icon: "person.crop.circle.badge.questionmark",
                        title: "No Patients Found",
                        message: viewModel.hasActiveFilters
                            ? "Try adjusting your filters"
                            : "No patients in the system yet"
                    )
                    .frame(height: 300)
                }
            } else {
                ForEach(viewModel.filteredPatients) { patient in
                    PatientCard(patient: patient, onTap: {
                        selectedPatient = patient
                    })
                    .contextMenu {
                        Button {
                            selectedPatient = patient
                        } label: {
                            Label("View Details", systemImage: "eye")
                        }
                        
                        Button(role: .destructive) {
                            Task {
                                await viewModel.deletePatient(patient)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Floating Search Bar
private struct FloatingSearchBar: View {
    @Binding var searchQuery: String
    let hasActiveFilters: Bool
    let onFilterTap: () -> Void
    let onClearFilters: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Search Field
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                    .font(.system(size: 16))
                
                TextField("Search", text: $searchQuery)
                    .textFieldStyle(.plain)
                
                if !searchQuery.isEmpty {
                    Button {
                        searchQuery = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray5))
            )
            
            // Microphone/Filter Button
            Button(action: onFilterTap) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "waveform")
                        .font(.system(size: 20))
                        .foregroundStyle(hasActiveFilters ? Color.accentColor : .blue)
                    
                    if hasActiveFilters {
                        Circle()
                            .fill(.red)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(.systemGray5))
                )
            }
        }
    }
}

// MARK: - Filter Sheet
private struct FilterSheet: View {
    @Bindable var viewModel: PatientSearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Sort By") {
                    ForEach(PatientSearchViewModel.SortOption.allCases, id: \.self) { option in
                        Button {
                            viewModel.selectedSortOption = option
                        } label: {
                            HStack {
                                Image(systemName: option.icon)
                                    .foregroundStyle(viewModel.selectedSortOption == option ? Color.accentColor : .secondary)
                                
                                Text(option.rawValue)
                                    .foregroundStyle(.primary)
                                
                                Spacer()
                                
                                if viewModel.selectedSortOption == option {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Filters & Sorting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset") {
                        viewModel.clearFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Add Patient View (Placeholder)
private struct AddPatientView: View {
    let viewModel: PatientSearchViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var fullName = ""
    @State private var dateOfBirth = Date()
    @State private var gender = "Male"
    @State private var phoneNumber = ""
    @State private var email = ""
    
    var body: some View {
        Form {
            Section("Basic Information") {
                TextField("Full Name", text: $fullName)
                
                DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                
                Picker("Gender", selection: $gender) {
                    Text("Male").tag("Male")
                    Text("Female").tag("Female")
                    Text("Other").tag("Other")
                }
                
                TextField("Phone Number", text: $phoneNumber)
                    .keyboardType(.phonePad)
                
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
            }
        }
        .navigationTitle("Add Patient")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Add") {
                    let newPatient = Patient(
                        id: UUID(),
                        fullName: fullName,
                        email: email.isEmpty ? nil : email,
                        phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
                        dateOfBirth: dateOfBirth.ISO8601Format(),
                        gender: gender,
                        createdAt: Date(),
                        bloodGroup: nil
                    )
                    Task {
                        await viewModel.addPatient(newPatient)
                        dismiss()
                    }
                }
                .fontWeight(.semibold)
                .disabled(fullName.isEmpty || phoneNumber.isEmpty)
            }
        }
    }
}

#Preview {
    NavigationStack {
        PatientSearchView()
    }
}
