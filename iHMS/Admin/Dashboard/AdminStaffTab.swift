import SwiftUI

struct AdminStaffTab: View {

    @State private var showAddStaffSheet = false
    @State private var doctors: [Staff] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var searchText = ""
    @State private var selectedDepartment: String? = nil

    private let staffService = StaffService()

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search doctors", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(18)

                Menu {
                    Button {
                        selectedDepartment = nil
                    } label: {
                        Label("All Departments", systemImage: "xmark.circle")
                    }

                    Divider()

                    ForEach(availableDepartments, id: \.self) { dept in
                        Button {
                            selectedDepartment = dept
                        } label: {
                            HStack {
                                Text(dept.capitalized)
                                if selectedDepartment == dept {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(
                            selectedDepartment == nil ? .secondary : .blue
                        )
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)

            // MARK: Active Filter Chip
            if let dept = selectedDepartment {
                Text("Filtered by \(dept.capitalized)")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .clipShape(Capsule())
                    .padding(.horizontal)
            }

            // MARK: List
            List {

                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView("Loading staff...")
                        Spacer()
                    }
                }

                ForEach(filteredDoctors) { doctor in
                    DoctorRowView(doctor: doctor)
                }
            }
            .listStyle(.insetGrouped)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAddStaffSheet) {
            AddStaffView()
        }
        .task {
            await loadDoctors()
        }
    }

    // MARK: Filtering Logic
    private var filteredDoctors: [Staff] {
        doctors.filter { doctor in
            let matchesSearch =
                searchText.isEmpty ||
                doctor.fullName.localizedCaseInsensitiveContains(searchText)

            let matchesDepartment =
                selectedDepartment == nil ||
                doctor.departmentId == selectedDepartment

            return matchesSearch && matchesDepartment
        }
    }

    private var availableDepartments: [String] {
        Array(Set(doctors.compactMap { $0.departmentId })).sorted()
    }

    // MARK: Data Loading
    private func loadDoctors() async {
        isLoading = true
        errorMessage = nil

        do {
            doctors = try await staffService.fetchStaff()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
