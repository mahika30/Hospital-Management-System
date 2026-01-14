//
//  CompletedTodayAppointmentsView.swift
//  iHMS
//
//  Created on 13/01/2026.
//

import SwiftUI
import Supabase
import Combine

struct CompletedTodayAppointmentsView: View {
    @StateObject private var viewModel: CompletedTodayAppointmentsViewModel
    
    init(staffId: UUID) {
        _viewModel = StateObject(wrappedValue: CompletedTodayAppointmentsViewModel(staffId: staffId))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.appointments.isEmpty {
                emptyState
            } else {
                appointmentsList
            }
        }
        .navigationTitle("Past Appointments")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task {
                        await viewModel.loadCompletedAppointments()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
        .task {
            await viewModel.loadCompletedAppointments()
        }
        .refreshable {
            await viewModel.loadCompletedAppointments()
        }
    }
    
    private var appointmentsList: some View {
        List(viewModel.appointments.filter { $0.patient != nil }, id: \.id) { appointment in
            NavigationLink {
                if let patient = appointment.patient {
                    ConsultationView(
                        appointment: appointment,
                        patient: patient,
                        staffId: viewModel.staffId
                    )
                }
            } label: {
                CompletedAppointmentRow(appointment: appointment)
            }
        }
        .listStyle(.plain)
        .id(viewModel.refreshID) // Force list refresh when refreshID changes
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 64))
                .foregroundColor(.gray)
            Text("No Completed Consultations")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Completed consultations will appear here")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

@MainActor
class CompletedTodayAppointmentsViewModel: ObservableObject {
    @Published var appointments: [Appointment] = []
    @Published var isLoading = false
    @Published var refreshID = UUID()
    
    let staffId: UUID
    
    init(staffId: UUID) {
        self.staffId = staffId
    }
    
    func loadCompletedAppointments() async {
        isLoading = true
        
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let todayString = dateFormatter.string(from: today)
            let tomorrowString = dateFormatter.string(from: tomorrow)
            
            let response: [Appointment] = try await SupabaseManager.shared.client
                .from("appointments")
                .select("""
                    *,
                    patients!inner(
                        id,
                        full_name,
                        date_of_birth,
                        gender,
                        phone_number,
                        blood_group,
                        allergies,
                        current_medications,
                        medical_history
                    ),
                    time_slots(
                        id,
                        start_time,
                        end_time
                    )
                """)
                .eq("staff_id", value: staffId.uuidString)
                .eq("status", value: "completed")
                .gte("appointment_date", value: todayString)
                .lt("appointment_date", value: tomorrowString)
                .order("appointment_date", ascending: true)
                .execute()
                .value
            
            appointments = response.sorted { apt1, apt2 in
                guard let slot1 = apt1.timeSlot, let slot2 = apt2.timeSlot else {
                    return false
                }
                return slot1.startTime < slot2.startTime
            }
            
            refreshID = UUID() // Force view refresh
            
            print("✅ Loaded \(appointments.count) completed appointments")
            for apt in appointments {
                print("   - Patient: \(apt.patient?.fullName ?? "nil"), Status: \(apt.status)")
            }
        } catch {
            print("❌ Error loading completed appointments: \(error)")
        }
        
        isLoading = false
    }
}
