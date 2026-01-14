//
//  BookAppointmentView.swift
//  iHMS
//
//  Created by Navdeep Singh on 08/01/26.
//

import SwiftUI
import Supabase
import Auth
import PostgREST


import Foundation

struct PaymentInsert: Encodable {
    let patient_id: UUID
    let appointment_id: UUID
    let amount: Int
    let status: String
    let payment_method: String
    let transaction_id: String
}



struct BookAppointmentView: View {

    // MARK: - Inputs
    let selectedDoctor: Staff

    // MARK: - State
    @State private var paymentCompleted = false
    private let consultationFee = 250
    @State private var showPaymentOverlay = false
    @State private var isPaying = false
    @State private var bookedSlotTime: String?
    @State private var transactionId: String?


    @StateObject private var viewModel = BookAppointmentViewModel()
//    @State private var showConfirm = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                doctorCard
                aiSuggestionsSection
                dateSection
                timeSlotSection
                if viewModel.selectedSlot != nil {
                    paymentSection
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
            }
            .padding()
        }
        .navigationTitle("Book Appointment")
        .navigationBarTitleDisplayMode(.large)
//        .alert(
//            "Confirm Appointment",
//            isPresented: $showConfirm
//        ) {
//            Button("Confirm") {
//                Task {
//                    if let slot = viewModel.selectedSlot {
//                        await viewModel.bookAppointment(
//                            doctorId: selectedDoctor.id
//                        )
//                    }
//                }
//            }
//
//            Button("Cancel", role: .cancel) {}
//        } message: {
//            if let slot = viewModel.selectedSlot {
//                Text("Book appointment for \(slot.timeRange)?")
//            }
//        }
        .alert("Appointment Booked!", isPresented: $viewModel.bookingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let slotTime = bookedSlotTime {
                Text(
                    "Your appointment for \(slotTime) has been successfully booked. " +
                    "You can view it in your upcoming appointments."
                )
            } else {
                Text(
                    "Your appointment has been successfully booked. " +
                    "You can view it in your upcoming appointments."
                )
            }
        }

        .fullScreenCover(isPresented: $showPaymentOverlay) {
            PaymentConfirmationView(isPaying: isPaying)
        }
        .task {
            await viewModel.loadSlots(
                staffId: selectedDoctor.id,
                date: viewModel.selectedDate
            )
            await viewModel.loadAISuggestions(forDoctor: selectedDoctor.id)
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
    
    var aiSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.headline)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue, .cyan],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("AI Recommended Slots")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.isLoadingSuggestions {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if viewModel.isLoadingSuggestions {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        ProgressView()
                        Text("Finding best slots for you...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding()
            } else if viewModel.suggestedSlots.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.rectangle.stack")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                    
                    Text("Book a few appointments to get personalized suggestions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.suggestedSlots) { suggestion in
                            Button {
                                // Parse date and load that doctor's slots
                                if let date = parseSuggestionDate(suggestion.date) {
                                    viewModel.selectedDate = date
                                    Task {
                                        await viewModel.loadSlots(
                                            staffId: suggestion.staffId,
                                            date: date
                                        )
                                        // Auto-select the matching slot after loading
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            if let matchingSlot = viewModel.timeSlots.first(where: {
                                                $0.timeRange == suggestion.timeRange
                                            }) {
                                                viewModel.selectedSlot = matchingSlot
                                            }
                                        }
                                    }
                                }
                            } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    // Badge
                                    HStack(spacing: 4) {
                                        if suggestion.reason.contains("preferred") {
                                            Image(systemName: "star.fill")
                                                .font(.caption2)
                                            Text("Your Doctor")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                        } else {
                                            Image(systemName: "sparkles")
                                                .font(.caption2)
                                            Text("Recommended")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(suggestion.reason.contains("preferred") ? Color.purple.opacity(0.15) : Color.blue.opacity(0.15))
                                    )
                                    .foregroundStyle(suggestion.reason.contains("preferred") ? .purple : .blue)
                                    
                                    // Doctor info
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.staffName)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)
                                            .foregroundStyle(.primary)
                                            .lineLimit(1)
                                        
                                        Text(formatSuggestionDate(suggestion.date))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Divider()
                                    
                                    // Time
                                    HStack(spacing: 6) {
                                        Image(systemName: "clock.fill")
                                            .font(.caption)
                                            .foregroundStyle(.blue)
                                        
                                        Text(suggestion.timeRange)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundStyle(.primary)
                                    }
                                    
                                    // Reason
                                    Text(suggestion.reason)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                .frame(width: 180)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: suggestion.reason.contains("preferred") 
                                                    ? [.purple.opacity(0.3), .blue.opacity(0.3)]
                                                    : [.blue.opacity(0.2), .cyan.opacity(0.2)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
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
    
    private func parseSuggestionDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func formatSuggestionDate(_ dateString: String) -> String {
        guard let date = parseSuggestionDate(dateString) else { return dateString }
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
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
                                        
                                        Text("\(slot.availableSlots)/\(slot.maxCapacity ?? 0) available")
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
//            showConfirm = true
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
                    .fill(
                        viewModel.selectedSlot == nil ||
                        viewModel.isLoading ||
                        !paymentCompleted
                        ? Color.gray
                        : Color.blue
                    )
            )

            .foregroundStyle(.white)
        }
        .disabled(
            viewModel.selectedSlot == nil ||
            viewModel.isLoading ||
            !paymentCompleted
        ).onChange(of: viewModel.selectedSlot) {
            paymentCompleted = false
        }

        .padding(.top, 8)
    }
}
private extension BookAppointmentView {

    var paymentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Consultation Fees")
                .font(.headline)

            HStack {
                Text("Amount")
                    .foregroundStyle(.secondary)

                Spacer()

                Text("₹\(consultationFee)")
                    .font(.title3)
                    .fontWeight(.bold)
            }

            if paymentCompleted {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)

                    Text("Payment Completed")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                }
            } else {
                Button {
                    showPaymentOverlay = true
                    isPaying = true

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isPaying = false

                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {

                            let txId = UUID().uuidString
                            transactionId = txId

                            withAnimation {
                                paymentCompleted = true
                            }

                            Task {
                                do {
                                    // ✅ CAPTURE SLOT TIME FIRST
                                    bookedSlotTime = viewModel.selectedSlot?.timeRange

                                    let appointmentId = try await viewModel
                                        .bookAppointmentAndReturnId(doctorId: selectedDoctor.id)

                                    let userId = try await SupabaseManager.shared.client.auth.session.user.id

                                    let payment = PaymentInsert(
                                        patient_id: userId,
                                        appointment_id: appointmentId,
                                        amount: consultationFee,
                                        status: "paid",
                                        payment_method: "upi",
                                        transaction_id: UUID().uuidString
                                    )

                                    try await SupabaseManager.shared.client.database
                                        .from("payments")
                                        .insert(payment)
                                        .execute()

                                    paymentCompleted = true

                                } catch {
                                    viewModel.errorMessage = "Payment or booking failed"
                                    paymentCompleted = false
                                }
                            }




                            showPaymentOverlay = false
                        }


                    }
                } label: {
                    Text("Pay ₹\(consultationFee) & Confirm")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(12)
                }
                .disabled(isPaying)

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

struct PaymentConfirmationView: View {

    let isPaying: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                if isPaying {
                    ProgressView()
                        .scaleEffect(1.6)
                        .tint(.white)

                    Text("Processing Payment…")
                        .foregroundStyle(.white)
                        .font(.headline)
                } else {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.green)

                    Text("Payment Successful")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                }
            }
        }
    }
}
