import SwiftUI

struct StaffProfileView: View {
    @StateObject var viewModel: StaffProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel // Needed for logout
    var isOwner: Bool = true // If true, shows Logout. If false (Admin viewing), hides Logout.
    @Environment(\.dismiss) var dismiss
    
    init(staff: Staff, isOwner: Bool = true) {
        _viewModel = StateObject(wrappedValue: StaffProfileViewModel(staff: staff))
        self.isOwner = isOwner
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Header
                ProfileHeaderView(
                    image: Image(systemName: "person.crop.circle"), // Placeholder
                    name: viewModel.fullName,
                    role: viewModel.role,
                    location: viewModel.locationString
                )
                .padding(.top)
                
                // Personal Information
                EditableInfoSection(
                    title: "Personal Information",
                    isEditing: $viewModel.isEditingPersonal,
                    onSave: {
                        Task { await viewModel.savePersonalInformation() }
                    }
                ) {
                    // Read Mode
                    VStack(spacing: 12) {
                        InfoRowView(label: "Full Name", value: viewModel.fullName)
                        
                        InfoRowView(label: "Phone Number", value: viewModel.phone)
                        
                        InfoRowView(label: "Email Address", value: viewModel.email)
                        

                    }
                } editContent: {
                    // Edit Mode
                    VStack(spacing: 12) {
                        CustomTextField(title: "Full Name", text: $viewModel.fullName)
                        
                        CustomTextField(title: "Phone Number", text: $viewModel.phone)
                            .keyboardType(.phonePad)
                        
                        // Read-only in Edit Mode
                        InfoRowView(label: "Email Address", value: viewModel.email)
                            .opacity(0.7)
                        

                    }
                }
                
                // Professional Details (Admin Only Edit)
                if !isOwner {
                    // Admin View: Editable
                    EditableInfoSection(
                        title: "Professional Details",
                        isEditing: $viewModel.isEditingRole,
                        onSave: {
                            Task { await viewModel.saveRoleAndDepartment() }
                        }
                    ) {
                        // Read Mode
                        VStack(spacing: 12) {
                            InfoRowView(label: "Designation", value: viewModel.designation)
                            InfoRowView(label: "Department", value: viewModel.departmentName)
                        }
                    } editContent: {
                        // Edit Mode
                        VStack(spacing: 12) {
                            CustomTextField(title: "Designation", text: $viewModel.designation)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Department")
                                    .font(.caption)
                                    .foregroundColor(Theme.secondaryText)
                                    .textCase(.uppercase)
                                
                                Menu {
                                    Picker("Department", selection: $viewModel.departmentId) {
                                        ForEach(viewModel.departments, id: \.id) { dept in
                                            Text(dept.name).tag(dept.id)
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Text(viewModel.departmentName)
                                            .foregroundColor(.white)
                                        Spacer()
                                        Image(systemName: "chevron.up.chevron.down")
                                            .foregroundColor(Theme.primaryText)
                                            .font(.caption)
                                    }
                                    .padding()
                                    .background(Theme.background)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                } else {
                    // Doctor View: Read Only
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Professional Details")
                            .font(.headline)
                            .foregroundColor(Theme.primaryText)
                        
                        VStack(spacing: 12) {
                            InfoRowView(label: "Designation", value: viewModel.designation)
                            InfoRowView(label: "Department", value: viewModel.departmentName)
                        }
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.cornerRadius)
                    }
                }
                
                // Logout Section (Only if Owner)
                if isOwner {
                    Button(role: .destructive) {
                        Task {
                            await authVM.signOut()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Log Out")
                        }
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Theme.cardBackground)
                        .cornerRadius(Theme.cornerRadius)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Doctor Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
}
