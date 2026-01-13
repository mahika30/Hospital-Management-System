import SwiftUI

struct AdminSettingsTab: View {
    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var profileVM = AdminProfileViewModel()
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    ProfileHeaderView(
                        image: Image(systemName: "person.crop.circle"),
                        name: profileVM.fullName,
                        role: profileVM.role
                    )
                    .padding(.top)
                    
                    EditableInfoSection(
                        title: "Personal Information",
                        isEditing: $profileVM.isEditingPersonal,
                        onSave: profileVM.savePersonalInformation
                    ) {

                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                InfoRowView(label: "First Name", value: profileVM.firstName)
                                InfoRowView(label: "Last Name", value: profileVM.lastName)
                            }
                            
                            InfoRowView(label: "Date of Birth", value: profileVM.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                            
                            InfoRowView(label: "Phone Number", value: profileVM.phone)

                            InfoRowView(label: "Email Address", value: profileVM.email)
                            
                            InfoRowView(label: "Role", value: profileVM.role)
                        }
                    } editContent: {
                        // Edit Mode
                        VStack(spacing: 12) {
                            HStack(spacing: 16) {
                                CustomTextField(title: "First Name", text: $profileVM.firstName)
                                CustomTextField(title: "Last Name", text: $profileVM.lastName)
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Date of Birth")
                                    .font(.caption)
                                    .foregroundColor(Theme.secondaryText)
                                    .textCase(.uppercase)
                                
                                DatePicker("", selection: $profileVM.dateOfBirth, displayedComponents: .date)
                                    .labelsHidden()
                                    .colorScheme(.dark)
                                    .accentColor(Theme.accent)
                                    .padding(.vertical, 4)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)

                            CustomTextField(title: "Phone Number", text: $profileVM.phone)
                                .keyboardType(.phonePad)
                            
                            InfoRowView(label: "Email Address", value: profileVM.email)
                                .opacity(0.7)
                            
                            InfoRowView(label: "Role", value: profileVM.role)
                                .opacity(0.7)
                        }
                    }
                    
                    Button(role: .destructive) {
                        Task {
                            await authVM.signOut()
                            dismiss()
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
                .padding()
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                            .padding(8)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
            }
        }
    }
}
