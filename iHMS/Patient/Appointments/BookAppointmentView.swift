//
//  BookAppointmentView.swift
//  iHMS
//
//  Created by Navdeep Singh on 08/01/26.
//

import SwiftUI

struct BookAppointmentView: View {

    // MARK: - Inputs
    let selectedDoctor: Staff

    // MARK: - State
    @StateObject private var viewModel = BookAppointmentViewModel()
    @State private var showConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                doctorCard
                dateSection
                timeSlotSection
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                confirmButton
            }
            .padding()
        }
        .navigationTitle("Book Appointment")
        .navigationBarTitleDisplayMode(.large)
        .alert(
            "Confirm Appointment",
            isPresented: $showConfirm
        ) {
            Button("Confirm") {
                Task {
                    if let slot = viewModel.selectedSlot {
                        await viewModel.bookAppointment(
                            doctorId: selectedDoctor.id
                        )
                    }
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if let slot = viewModel.selectedSlot {
                Text("Book appointment for \(slot.timeRange)?")
            }
        }
        .alert("Appointment Booked!", isPresented: $viewModel.bookingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your appointment has been successfully booked. You can view it in your upcoming appointments.")
        }
        .task {
            await viewModel.loadSlots(
                staffId: selectedDoctor.id,
                date: viewModel.selectedDate
            )
        }
    }
}

private extension BookAppointmentView {

    var doctorCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                // Profile Image
                if let profileImage = selectedDoctor.profileImage, !profileImage.isEmpty {
                    AsyncImage(url: URL(string: profileImage)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .overlay {
                                Text(selectedDoctor.fullName.prefix(1))
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 70, height: 70)
                        .overlay {
                            Text(selectedDoctor.fullName.prefix(1))
                                .font(.title)
                                .fontWeight(.semibold)
                                .foregroundStyle(.white)
                        }
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(selectedDoctor.fullName)
                        .font(.title3)
                        .fontWeight(.bold)
                    
                    if let designation = selectedDoctor.designation {
                        Text(designation)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    // Show department name from department_id
                    if let deptId = selectedDoctor.departmentId {
                        let departmentName: String = {
                            switch deptId {
                            case "general": return "General Medicine"
                            case "cardiology": return "Cardiology"
                            case "neurology": return "Neurology"
                            case "neurosurgery": return "Neurosurgery"
                            case "orthopedics": return "Orthopedics"
                            case "physiotherapy": return "Physiotherapy"
                            case "sports_medicine": return "Sports Medicine"
                            case "pediatrics": return "Pediatrics"
                            case "neonatology": return "Neonatology"
                            case "gynecology": return "Gynecology"
                            case "obstetrics": return "Obstetrics"
                            case "ent": return "ENT"
                            case "ophthalmology": return "Ophthalmology"
                            case "psychiatry": return "Psychiatry"
                            case "psychology": return "Psychology"
                            case "dermatology": return "Dermatology"
                            case "endocrinology": return "Endocrinology"
                            case "radiology": return "Radiology"
                            case "pathology": return "Pathology"
                            case "laboratory": return "Laboratory Medicine"
                            case "gastroenterology": return "Gastroenterology"
                            case "pulmonology": return "Pulmonology"
                            case "nephrology": return "Nephrology"
                            case "urology": return "Urology"
                            case "general_surgery": return "General Surgery"
                            case "cardiac_surgery": return "Cardiac Surgery"
                            case "plastic_surgery": return "Plastic Surgery"
                            case "emergency": return "Emergency Medicine"
                            case "critical_care": return "Critical Care / ICU"
                            default: return deptId.capitalized
                            }
                        }()
                        
                        HStack(spacing: 6) {
                            Image(systemName: "stethoscope")
                                .font(.caption)
                            Text(departmentName)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray4), lineWidth: 1)
        )
    }
}

private extension BookAppointmentView {

    var dateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Date")
                .font(.headline)
            
            DatePicker(
                "Appointment Date",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .onChange(of: viewModel.selectedDate) {
                viewModel.bookingSuccess = false
                Task {
                    await viewModel.loadSlots(
                        staffId: selectedDoctor.id,
                        date: viewModel.selectedDate
                    )
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray4), lineWidth: 1)
        )
    }
}

private extension BookAppointmentView {

    var timeSlotSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Time Slot")
                .font(.headline)

            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding()
            }
            else if viewModel.timeSlots.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No slots available for this date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
            else {
                VStack(spacing: 12) {
                    ForEach(viewModel.timeSlots) { slot in
                        Button {
                            viewModel.selectedSlot = slot
                        } label: {
                            HStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(slot.timeRange)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    
                                    HStack(spacing: 6) {
                                        Text(slot.shortDayName)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("•")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        
                                        Text("\(slot.availableSlots)/\(slot.maxCapacity) available")
                                            .font(.caption)
                                            .foregroundStyle(slot.availableSlots > 3 ? .green : (slot.availableSlots > 0 ? .orange : .red))
                                    }
                                }

                                Spacer()

                                if viewModel.selectedSlot?.id == slot.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                } else {
                                    Image(systemName: "circle")
                                        .font(.title2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(viewModel.selectedSlot?.id == slot.id ? Color.blue.opacity(0.1) : Color(.systemGray6))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(viewModel.selectedSlot?.id == slot.id ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(Color(.systemGray4), lineWidth: 1)
        )
    }
}

private extension BookAppointmentView {

    var confirmButton: some View {
        Button {
            showConfirm = true
        } label: {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                
                Text("Confirm Appointment")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(viewModel.selectedSlot == nil || viewModel.isLoading ? Color.gray : Color.blue)
            )
            .foregroundStyle(.white)
        }
        .disabled(viewModel.selectedSlot == nil || viewModel.isLoading)
        .padding(.top, 8)
    }
}
