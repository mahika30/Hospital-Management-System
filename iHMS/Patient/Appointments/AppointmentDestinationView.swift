
import SwiftUI
import Supabase

struct AppointmentDestinationView: View {
    let appointment: Appointment
    @State private var prescription: Prescription?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if appointment.status.lowercased() == "completed" {
                if let prescription = prescription {
                    PrescriptionDetailView(prescription: prescription)
                } else if isLoading {
                    ProgressView("Loading prescription...")
                } else {
                    // Fallback if no prescription found even if completed
                     PatientAppointmentDetailView(appointment: appointment)
                }
            } else {
                PatientAppointmentDetailView(appointment: appointment)
            }
        }
        .task {
            if appointment.status.lowercased() == "completed" {
                await fetchPrescription()
            }
        }
    }
    
    private func fetchPrescription() async {
        guard prescription == nil else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let response: [Prescription] = try await SupabaseManager.shared.client
                .from("prescriptions")
                .select("""
                    *,
                    prescription_medicines(*)
                """)
                .eq("appointment_id", value: appointment.id)
                .execute()
                .value
            
            if let fetchedPrescription = response.first {
                self.prescription = fetchedPrescription
            }
        } catch {
            print("Error fetching prescription: \(error)")
        }
    }
}
