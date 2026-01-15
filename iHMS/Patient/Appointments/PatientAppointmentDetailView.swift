
import SwiftUI

struct PatientAppointmentDetailView: View {
    let appointment: Appointment
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card (Doctor & Date)
                headerCard
                
                // Reason Card (like Diagnosis)
                if let reason = appointment.reasonForVisit {
                    reasonCard(reason)
                }
                
                // Details Section (Time, Department, etc.)
                detailsSection
            }
            .padding()
        }
        .navigationTitle("Appointment Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var isMissed: Bool {
        let status = appointment.status.lowercased()
        guard status != "completed" && status != "cancelled" else { return false }
        
        let today = Date()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        
        // Simple comparison: if appointment date string is lexicographically smaller than today's date string
        // This relies on the format being YYYY-MM-DD which is sortable
        return appointment.appointmentDate < formatter.string(from: today)
    }
    
    var statusText: String {
        if isMissed { return "Missed" }
        return appointment.appointmentStatus.displayName
    }
    
    var statusColor: Color {
        if isMissed { return .red }
        return appointment.appointmentStatus.color
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.blue)
                        Text("Dr. \(appointment.doctorName)")
                            .font(.title3)
                            .fontWeight(.semibold)
                    }
                    Text(appointment.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Badge
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.15))
                    .foregroundColor(statusColor)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func reasonCard(_ reason: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Reason for Visit", systemImage: "text.bubble")
                .font(.headline)
            
            Text(reason)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Details", systemImage: "info.circle.fill")
                .font(.headline)
            
            VStack(spacing: 12) {
                if let slot = appointment.timeSlot {
                    detailRow(icon: "clock", title: "Time", value: slot.timeRange)
                } else if let time = appointment.appointmentTime {
                     detailRow(icon: "clock", title: "Time", value: time)
                }
                
                if let design = appointment.staff?.designation {
                     detailRow(icon: "person.text.rectangle", title: "Doctor Designation", value: design)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
        }
        .font(.subheadline)
    }
}
