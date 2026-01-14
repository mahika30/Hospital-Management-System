import SwiftUI
internal import Realtime

struct InfoCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(white: 0.15))
        .cornerRadius(10)
    }
}

struct AppointmentCard: View {
    let appointment: Appointment

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "stethoscope")
                    .font(.title3)
                    .foregroundColor(.blue)

                Spacer()

                Text(appointment.appointmentStatus.displayName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(appointment.appointmentStatus.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(appointment.appointmentStatus.color.opacity(0.2))
                    .cornerRadius(6)
            }

            Text("Dr. \(appointment.doctorName)")
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(1)

            // Date & Time
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(appointment.formattedDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let slot = appointment.timeSlot {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(slot.timeRange)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .frame(width: 200, height: 160)
        .background(Color(white: 0.15))
        .cornerRadius(16)
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {

                ZStack {
                    Circle()
                        .fill(tint.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(white: 0.12))
            .cornerRadius(16)
        }
    }
}

// MARK: - Dashboard View
struct PatientDashboardView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @StateObject private var viewModel = PatientViewModel()
    @State private var navigateToPayments = false

    @State private var showingProfile = false
    @State private var showQROverlay = false
    @State private var navigateToDoctorList = false
    @State private var navigateToPastAppointments = false

    var body: some View {
        NavigationStack {
            NavigationLink(
                destination: DoctorListView(),
                isActive: $navigateToDoctorList
            ) {
                EmptyView()
            }
            
            NavigationLink(
                destination: PastAppointmentsView(patientId: viewModel.patient?.id ?? UUID()),
                isActive: $navigateToPastAppointments
            ) {
                EmptyView()
            }
            NavigationLink(
                destination: PaymentHistoryView(
                    patientName: viewModel.name   
                ),
                isActive: $navigateToPayments
            ) {
                EmptyView()
            }



            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        hospitalIDCard
                        upcomingAppointmentsSection
                        quickActionsSection
                    }
                    .padding()
                }

                if showQROverlay {
                    qrOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("iHMS")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingProfile, onDismiss: {
                Task {
                    await viewModel.loadDashboardData(authVM: authVM)
                }
            }) {
                NavigationStack {
                    PatientProfileView(viewModel: viewModel)
                        .environmentObject(authVM)
                }
            }
        }
        .task {
            await viewModel.loadDashboardData(authVM: authVM)
        }
    }

    // MARK: - Hospital Card
    private var hospitalIDCard: some View {
        VStack(alignment: .leading, spacing: 18) {

            Text("Digital Patient Card")
                .font(.caption)
                .foregroundColor(.gray)

            HStack {
                VStack(alignment: .leading, spacing: 12) {
                    Text(viewModel.name)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    HStack(spacing: 10) {
                        infoPill("Age", "\(viewModel.age)")
                        infoPill("Gender", viewModel.gender)
                        infoPill("Blood", viewModel.bloodGroup)
                    }
                }

                Spacer()

                QRCodeView(data: viewModel.qrCodeData)
                    .frame(width: 90, height: 90)
                    .onTapGesture {
                        showQROverlay = true
                    }
            }

            Text("Scan this QR at hospital reception")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.4), Color.black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(28)
    }

    // MARK: - Appointments
    private var upcomingAppointmentsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Upcoming Appointments")

            if viewModel.appointments.isEmpty {
                Text("No upcoming appointments")
                    .foregroundColor(.gray)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 14) {
                        ForEach(viewModel.appointments) { appointment in
                            AppointmentCard(appointment: appointment)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader("Quick Actions")

            VStack(spacing: 12) {
                QuickActionCard(
                    icon: "calendar.badge.plus",
                    title: "Book Appointment",
                    subtitle: "Schedule a doctor visit",
                    tint: .blue
                ) {
                    navigateToDoctorList = true
                }


                QuickActionCard(
                    icon: "clock.arrow.circlepath",
                    title: "Past Appointments",
                    subtitle: "View appointment history",
                    tint: .orange
                ){
                    navigateToPastAppointments = true
                }
                
                QuickActionCard(
                    icon: "doc.text.fill",
                    title: "Medical Records",
                    subtitle: "View reports & prescriptions",
                    tint: .purple
                ){
                    navigateToDoctorList = false
                }

                QuickActionCard(
                    icon: "creditcard.fill",
                    title: "Payments & Bills",
                    subtitle: "Invoices and transactions",
                    tint: .green
                ){
                    navigateToPayments = true
                }

            }
        }
    }

    private var qrOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .ignoresSafeArea()
                .onTapGesture { showQROverlay = false }

            QRCodeView(data: viewModel.qrCodeData)
                .frame(width: 260, height: 260)
                .padding()
                .background(Color(white: 0.12))
                .cornerRadius(26)
        }
    }

    private func infoPill(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.gray)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.12))
        .cornerRadius(14)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }
}

// MARK: - Preview
struct PatientDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDashboardView()
    }
}
