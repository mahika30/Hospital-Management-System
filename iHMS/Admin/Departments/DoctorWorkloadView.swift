import SwiftUI

struct DoctorWorkloadView: View {
    let doctor: Staff
    @Environment(\.dismiss) var dismiss
    
    @State private var appointments: [Appointment] = []
    @State private var isLoading = false
    @State private var selectedTimeRange: WorkloadTimeRange = .today
    @State private var errorMessage: String?
    
    private let appointmentService = AppointmentService()
    
    enum WorkloadTimeRange: String, CaseIterable {
        case today = "Today"
        case week = "This Week"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "stethoscope.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                        .padding(.top, 20)
                    
                    Text(doctor.fullName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(doctor.specialization ?? "General Physician")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 10)
                    
                    Picker("Time Range", selection: $selectedTimeRange) {
                        ForEach(WorkloadTimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .background(Color(.secondarySystemBackground))
                
                // Stats
                HStack {
                    VStack(spacing: 4) {
                        Text("\(appointments.count)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text("Appointments")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
                .background(Color(.systemBackground))
                
                Divider()
                
                // List
                if isLoading {
                    Spacer()
                    ProgressView()
                    Spacer()
                } else if appointments.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No appointments found")
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(appointments) { appointment in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(appointment.formattedTime)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(appointment.patient?.fullName ?? "Unknown Patient")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text(appointment.status.capitalized)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(statusColor(for: appointment.status).opacity(0.15))
                                    .foregroundColor(statusColor(for: appointment.status))
                                    .clipShape(Capsule())
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Workload")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onChange(of: selectedTimeRange) { _ in
                Task { await fetchWorkload() }
            }
            .task {
                await fetchWorkload()
            }
        }
    }
    
    private func fetchWorkload() async {
        isLoading = true
        errorMessage = nil
        
        let calendar = Calendar.current
        let now = Date()
        let start: Date
        let end: Date
        
        switch selectedTimeRange {
        case .today:
            start = calendar.startOfDay(for: now)
            end = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now) ?? now
        case .week:
            let startOfWeek = calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: now).date!
            start = startOfWeek
            end = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        }
        
        do {
            appointments = try await appointmentService.fetchDoctorAppointments(
                staffId: doctor.id,
                from: start,
                to: end
            )
        } catch {
            errorMessage = error.localizedDescription
            print("Error fetching workload: \(error)")
        }
        
        isLoading = false
    }
    
    private func statusColor(for status: String) -> Color {
        switch status.lowercased() {
        case "scheduled": return .blue
        case "confirmed": return .green
        case "cancelled": return .red
        case "completed": return .gray
        default: return .orange
        }
    }
}
