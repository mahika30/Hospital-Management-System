//
//  ManageAvailabilityView.swift
//  iHMS
//
//  Created on 08/01/2026.
//

import SwiftUI

struct ManageAvailabilityView: View {
    let staff: Staff
    @State private var viewModel: AvailabilityViewModel
    @State private var showingMenu = false
    @State private var showingEmergencyCancel = false
    @State private var showingRunningLate = false
    @State private var runningLateSlot: TimeSlot?
    @State private var showingCapacityEditor: TimeSlot?
    @State private var showingConflictAlert = false
    @State private var showingSuccessToast = false
    @State private var successMessage = ""
    @State private var conflictSlot: TimeSlot?
    @State private var conflictAppointments: [Appointment] = []
    
    init(staff: Staff) {
        self.staff = staff
        _viewModel = State(initialValue: AvailabilityViewModel(staff: staff))
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    StaffHeaderView(staff: staff)
 
                    datePickerSection
                
                    if viewModel.isLoading {
                        LoadingView()
                    } else if let error = viewModel.errorMessage {
                        errorView(error)
                    } else if viewModel.timeSlots.isEmpty {
                        EmptyStateView(
                            icon: "calendar.badge.exclamationmark",
                            title: "No Slots Available",
                            message: "No time slots found for this date.",
                            actionTitle: nil,
                            action: nil
                        )
                    } else {
                        timeSlotsSection
                    }
                }
                .padding()
            }
            if showingSuccessToast {
                successToastView
            }
        }
        .navigationTitle("Manage Your Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        Task {
                            await viewModel.enableWeekdays(startDate: viewModel.selectedDate, weeks: 4)
                            showSuccess("Weekdays enabled")
                        }
                    } label: {
                        Label("Enable Weekdays (4 weeks)", systemImage: "calendar")
                    }
                    
                    Button {
                        Task {
                            await viewModel.enableWeekend(startDate: viewModel.selectedDate, weeks: 4)
                            showSuccess("Weekend enabled")
                        }
                    } label: {
                        Label("Enable Weekend (4 weeks)", systemImage: "calendar.badge.clock")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        Task {
                            await viewModel.disableAllSlots()
                            showSuccess("All slots disabled")
                        }
                    } label: {
                        Label("Disable All for This Date", systemImage: "xmark.circle")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                }
            }
        }
        .sheet(isPresented: $showingEmergencyCancel) {
            emergencyCancelSheet
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showingRunningLate) {
            runningLateSheet
        }
        .sheet(item: $showingCapacityEditor) { slot in
            capacityEditorSheet(for: slot)
        }
        .alert("Appointments Conflict", isPresented: $showingConflictAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Continue", role: .destructive) {
                if let slot = conflictSlot {
                    showingEmergencyCancel = true
                }
            }
        } message: {
            if let slot = conflictSlot {
                Text("This slot has \(slot.currentBookings ?? 0) booked appointment(s):\n\n• Vikram Singh\n\nYou need to provide a cancellation reason.")
            }
        }
        .task {
            await viewModel.loadTimeSlots()
        }
        .onChange(of: viewModel.selectedDate) { _, _ in
            Task {
                await viewModel.loadTimeSlots()
            }
        }
    }
    
    private var datePickerSection: some View {
        VStack(spacing: 8) {
            DatePicker(
                "Select Date",
                selection: $viewModel.selectedDate,
                displayedComponents: .date
            )
            .datePickerStyle(.graphical)
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            // Day name as secondary text
            Text(viewModel.selectedDayName)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
    }
    
    private var timeSlotsSection: some View {
        VStack(spacing: 16) {
            // Morning Section
            if !viewModel.morningSlots.isEmpty {
                sectionView(title: "Morning", icon: "sunrise.fill", slots: viewModel.morningSlots)
            }
            
            // Afternoon Section
            if !viewModel.afternoonSlots.isEmpty {
                sectionView(title: "Afternoon", icon: "sun.max.fill", slots: viewModel.afternoonSlots)
            }
            
            // Evening Section
            if !viewModel.eveningSlots.isEmpty {
                sectionView(title: "Evening", icon: "moon.stars.fill", slots: viewModel.eveningSlots)
            }
        }
    }
    
    private func sectionView(title: String, icon: String, slots: [TimeSlot]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.headline)
                Text("\(slots.filter { $0.isAvailable ?? false }.count)/\(slots.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(slots) { slot in
                    AvailabilityTimeSlotCard(
                        slot: slot,
                        viewModel: viewModel,
                        onToggle: { newValue in
                            handleToggle(slot: slot, newValue: newValue)
                        },
                        onCapacityTap: {
                            showingCapacityEditor = slot
                        },
                        onEmergencyCancel: {
                            conflictSlot = slot
                            showingEmergencyCancel = true
                        },
                        onRunningLate: {
                            runningLateSlot = slot
                            showingRunningLate = true
                        }
                    )
                }
            }
        }
    }
    
    private func handleToggle(slot: TimeSlot, newValue: Bool) {
        if !newValue && (slot.currentBookings ?? 0) > 0 {
            conflictSlot = slot
            showingConflictAlert = true
        } else {
            Task {
                await viewModel.toggleSlot(slot, isAvailable: newValue)
            }
        }
    }
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundStyle(.orange)
            
            Text("Error")
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Retry") {
                Task {
                    await viewModel.loadTimeSlots()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var emergencyCancelSheet: some View {
        NavigationView {
            EmergencyCancellationDialog(
                appointments: conflictAppointments,
                onConfirm: { reason in
                    Task {
                        // Handle cancellation
                        showingEmergencyCancel = false
                        if let slot = conflictSlot {
                            await viewModel.toggleSlot(slot, isAvailable: false)
                        }
                        showSuccess("Slot cancelled")
                    }
                },
                onCancel: {
                    showingEmergencyCancel = false
                }
            )
            .navigationTitle("Emergency Cancellation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingEmergencyCancel = false
                    }
                }
            }
        }
        .presentationDetents([.large])
    }
    
    private var runningLateSheet: some View {
        NavigationView {
            RunningLateDialog(
                onConfirm: { minutes in
                    Task {
                        if let slot = runningLateSlot {
                            await viewModel.adjustDelay(slot, by: minutes)
                        }
                        showingRunningLate = false
                        showSuccess("Patients notified about \(minutes) min delay")
                    }
                },
                onCancel: {
                    showingRunningLate = false
                    runningLateSlot = nil
                }
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingRunningLate = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
    
    private func capacityEditorSheet(for slot: TimeSlot) -> some View {
        NavigationView {
            CapacityEditorView(
                slot: slot,
                onUpdate: { newCapacity in
                    Task {
                        await viewModel.updateCapacity(slot, capacity: newCapacity)
                        showingCapacityEditor = nil
                        showSuccess("Capacity updated")
                    }
                },
                onCancel: {
                    showingCapacityEditor = nil
                }
            )
            .navigationTitle("Adjust Capacity")
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium])
    }
    
    private var successToastView: some View {
        VStack {
            Spacer()
            
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("All Set!")
                        .font(.headline)
                    Text(successMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .animation(.spring(), value: showingSuccessToast)
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        withAnimation {
            showingSuccessToast = true
        }
        
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation {
                showingSuccessToast = false
            }
        }
    }
}

// MARK: - Staff Header
private struct StaffHeaderView: View {
    let staff: Staff
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue.gradient)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "stethoscope")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }
            
            Text(staff.fullName)
                .font(.title2)
                .fontWeight(.bold)
            
            // Show department name from department_id
            if let deptId = staff.departmentId {
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
            
            HStack(spacing: 16) {
                AvailabilityStatusBadge(
                    icon: "person.2.fill",
                    label: "Capacity",
                    value: "5 patients/hr",
                    color: .blue
                )
                
                AvailabilityStatusBadge(
                    icon: "checkmark.circle.fill",
                    label: "Status",
                    value: "Active",
                    color: .green
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

// MARK: - Status Badge
private struct AvailabilityStatusBadge: View {
    let icon: String
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(white: 0.1))
        .cornerRadius(12)
    }
}

// MARK: - Day Selector
private struct DaySelectorView: View {
    @Binding var selectedDay: Int
    
    private let days = [
        (1, "Sun"),
        (2, "Mon"),
        (3, "Tue"),
        (4, "Wed"),
        (5, "Thu"),
        (6, "Fri"),
        (7, "Sat")
    ]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(days, id: \.0) { day, name in
                    Button {
                        selectedDay = day
                    } label: {
                        VStack(spacing: 4) {
                            Text(name)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            if selectedDay == day {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        .frame(width: 70, height: 56)
                        .background(selectedDay == day ? Color.blue : Color(.systemGray6))
                        .foregroundColor(selectedDay == day ? .white : .primary)
                        .cornerRadius(14)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Time Slot Card
private struct AvailabilityTimeSlotCard: View {
    let slot: TimeSlot
    let viewModel: AvailabilityViewModel
    let onToggle: (Bool) -> Void
    let onCapacityTap: () -> Void
    let onEmergencyCancel: () -> Void
    let onRunningLate: () -> Void
    
    @State private var showingLongPressActions = false
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Time and Status Icon
                VStack(spacing: 4) {
                    Circle()
                        .fill((slot.isAvailable ?? false) ? Color.green : Color.gray)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: (slot.isRunningLate ?? false) ? "clock.badge.exclamationmark.fill" : "clock.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        )
                }
                
                // Slot Info
                VStack(alignment: .leading, spacing: 6) {
                    Text(slot.timeRange)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    HStack(spacing: 8) {
                        // Capacity Indicator
                        Button(action: onCapacityTap) {
                            HStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 3)
                                        .frame(width: 32, height: 32)
                                    
                                    Circle()
                                        .trim(from: 0, to: CGFloat(slot.currentBookings ?? 0) / CGFloat(slot.maxCapacity ?? 1))
                                        .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .frame(width: 32, height: 32)
                                        .rotationEffect(.degrees(-90))
                                    
                                    Text("\(slot.currentBookings ?? 0)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                }
                                
                                Text("/ \(slot.maxCapacity ?? 0)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Text((slot.isAvailable ?? false) ? "Booked" : "Disabled")
                            .font(.caption)
                            .foregroundStyle((slot.isAvailable ?? false) ? .green : .gray)
                    }
                }
                
                Spacer()
                
                // Toggle Only (removed three dots)
                Toggle("", isOn: Binding(
                    get: { slot.isAvailable ?? false },
                    set: { onToggle($0) }
                ))
                .labelsHidden()
            }
            .padding()
            
            // Running Late Banner with Delay Adjuster
            if (slot.isRunningLate ?? false) && (slot.delayMinutes ?? 0) > 0 {
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.badge.exclamationmark.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                        
                        Text("Running \(slot.delayMinutes ?? 0) min late")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Spacer()
                    
                    // Delay Adjuster
                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await viewModel.adjustDelay(slot, by: -15)
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.yellow)
                        }
                        
                        Button {
                            Task {
                                await viewModel.adjustDelay(slot, by: 15)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.yellow)
                        }
                        
                        Button {
                            Task {
                                await viewModel.clearRunningLate(slot)
                            }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 12)
                .background(Color.yellow.opacity(0.15))
            }
        }
        .background((slot.isAvailable ?? false) ? Color.green.opacity(0.05) : Color(.systemGray6))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((slot.isRunningLate ?? false) ? Color.yellow.opacity(0.5) : ((slot.isAvailable ?? false) ? Color.green.opacity(0.3) : Color.clear), lineWidth: 2)
        )
        .cornerRadius(12)
        .padding(.horizontal)
        .onLongPressGesture {
            // Show action sheet on long press
            showingLongPressActions = true
        }
        .confirmationDialog("Slot Actions", isPresented: $showingLongPressActions, titleVisibility: .visible) {
            if slot.isAvailable ?? false {
                Button("Emergency Cancel") {
                    onEmergencyCancel()
                }
                
                if slot.isRunningLate ?? false {
                    Button("Clear Running Late") {
                        Task {
                            await viewModel.clearRunningLate(slot)
                        }
                    }
                } else {
                    Button("Mark Running Late") {
                        onRunningLate()
                    }
                }
            }
            
            Button("Cancel", role: .cancel) {}
        }
    }
}

// MARK: - Capacity Editor View
private struct CapacityEditorView: View {
    let slot: TimeSlot
    let onUpdate: (Int) -> Void
    let onCancel: () -> Void
    
    @State private var capacity: Int
    
    init(slot: TimeSlot, onUpdate: @escaping (Int) -> Void, onCancel: @escaping () -> Void) {
        self.slot = slot
        self.onUpdate = onUpdate
        self.onCancel = onCancel
        _capacity = State(initialValue: slot.maxCapacity ?? 5)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Text(slot.timeRange)
                .font(.title3)
                .fontWeight(.semibold)
            
            HStack(spacing: 40) {
                Button {
                    if capacity > 1 {
                        capacity -= 1
                    }
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "minus")
                                .font(.title2)
                                .foregroundStyle(.white)
                        )
                }
                
                VStack(spacing: 4) {
                    Text("\(capacity)")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundStyle(.blue)
                    Text("patients per hour")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Button {
                    if capacity < 20 {
                        capacity += 1
                    }
                } label: {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundStyle(.white)
                        )
                }
            }
            
            if (slot.currentBookings ?? 0) > 0 {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.orange)
                    Text("Currently \(slot.currentBookings ?? 0) patients booked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
            
            Button {
                onUpdate(capacity)
            } label: {
                Text("Update Capacity")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Color.blue)
                    .cornerRadius(14)
            }
            .padding(.top)
        }
        .padding(24)
    }
}

// MARK: - Times Slots List (Legacy support)
private struct TimeSlotsListView: View {
    let timeSlots: [TimeSlot]
    let viewModel: AvailabilityViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time Slots")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 8) {
                ForEach(timeSlots) { slot in
                    TimeSlotRow(slot: slot, viewModel: viewModel)
                }
            }
        }
    }
}

// MARK: - Time Slot Row (Legacy)
private struct TimeSlotRow: View {
    let slot: TimeSlot
    let viewModel: AvailabilityViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(slot.timeRange)
                    .font(.headline)
                
                Text("\(slot.currentBookings ?? 0)/\(slot.maxCapacity ?? 0) booked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { slot.isAvailable ?? false },
                set: { newValue in
                    Task {
                        await viewModel.toggleSlot(slot, isAvailable: newValue)
                    }
                }
            ))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

